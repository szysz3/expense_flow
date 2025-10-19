#!/usr/bin/env python3

import os
import shutil
import sqlite3
from datetime import datetime
import sys
from pathlib import Path
import argparse

def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='Backup ExpenseFlow data')
    parser.add_argument('--source', default='.data',
                      help='Source directory to backup (default: .data)')
    parser.add_argument('--dest', default='/mnt/sdcard/expense_flow_backups/',
                      help='Destination directory for backups (default: /mnt/sdcard/expense_flow_backups/)')
    parser.add_argument('--max-backups', type=int, default=14,
                      help='Maximum number of backups to keep (default: 14)')
    return parser.parse_args()

def _backup_sqlite_file(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(source) as src_conn:
        with sqlite3.connect(destination) as dest_conn:
            src_conn.backup(dest_conn)


def _copy_path(source: Path, destination: Path) -> None:
    if source.is_dir():
        shutil.copytree(source, destination)
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def create_backup(source_dir, backup_dir, max_backups):
    """Create a consistent backup of the data directory"""
    source_path = Path(source_dir)
    if not source_path.is_dir():
        print(f"Error: Source directory not found: {source_dir}")
        return False

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = Path(backup_dir) / timestamp

    try:
        backup_path.mkdir(parents=True, exist_ok=True)
        print(f"Starting backup from {source_dir} to {backup_path}")

        for root, _, files in os.walk(source_path):
            root_path = Path(root)
            relative_root = root_path.relative_to(source_path)
            destination_root = backup_path / relative_root
            destination_root.mkdir(parents=True, exist_ok=True)

            for filename in files:
                source_item = root_path / filename
                destination = destination_root / filename

                if source_item.name.endswith((".sqlite3", ".sqlite")):
                    print(f"Backing up SQLite database {source_item} -> {destination}")
                    _backup_sqlite_file(source_item, destination)
                elif source_item.name.endswith((
                    ".sqlite3-wal",
                    ".sqlite3-shm",
                    ".sqlite-wal",
                    ".sqlite-shm",
                )):
                    # WAL/SHM sidecars copied verbatim for completeness
                    _copy_path(source_item, destination)
                else:
                    _copy_path(source_item, destination)

        total_size = sum(f.stat().st_size for f in backup_path.rglob("*"))
        print(f"Backup completed: {total_size / (1024 * 1024):.2f} MB")

        cleanup_old_backups(backup_dir, max_backups)
        return True

    except Exception as e:
        print(f"Backup failed: {str(e)}")
        if backup_path.exists():
            try:
                shutil.rmtree(backup_path)
            except Exception as cleanup_err:
                print(f"Could not clean up failed backup: {str(cleanup_err)}")
        return False

def cleanup_old_backups(backup_dir, max_backups):
    """Remove old backups keeping only the most recent max_backups"""
    try:
        # List all backup directories
        backups = sorted([d for d in os.listdir(backup_dir) 
                          if os.path.isdir(os.path.join(backup_dir, d))])
        
        # Remove oldest backups if we have more than max_backups
        if len(backups) > max_backups:
            print(f"Found {len(backups)} backups, keeping {max_backups}")
            for backup_to_remove in backups[:-max_backups]:
                path_to_remove = os.path.join(backup_dir, backup_to_remove)
                print(f"Removing old backup: {path_to_remove}")
                shutil.rmtree(path_to_remove)
        else:
            print(f"Found {len(backups)} backups, no cleanup needed")
            
    except Exception as e:
        print(f"Error during backup cleanup: {str(e)}")

def check_destination_available(backup_dir):
    """Check if the backup destination is available"""
    parent_dir = os.path.dirname(backup_dir)
    if not os.path.exists(parent_dir):
        print(f"Error: Backup destination parent directory not found: {parent_dir}")
        print("Is the SD card mounted?")
        return False
        
    # Check if we can write to the directory
    test_file = os.path.join(parent_dir, '.backup_test')
    try:
        with open(test_file, 'w') as f:
            f.write('test')
        os.remove(test_file)
        return True
    except Exception as e:
        print(f"Cannot write to backup destination: {str(e)}")
        return False

def main():
    """Main entry point"""
    args = parse_args()
    
    print("Starting ExpenseFlow backup")
    
    # Verify backup destination is available
    if not check_destination_available(args.dest):
        print("Backup aborted: destination not available")
        sys.exit(1)
    
    # Create backup
    success = create_backup(args.source, args.dest, args.max_backups)
    
    if success:
        print("Backup completed successfully")
        sys.exit(0)
    else:
        print("Backup failed")
        sys.exit(1)

if __name__ == "__main__":
    main()

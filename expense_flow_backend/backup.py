#!/usr/bin/env python3

import os
import shutil
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

def create_backup(source_dir, backup_dir, max_backups):
    """Create a backup of the source directory"""
    # Ensure source directory exists
    if not os.path.isdir(source_dir):
        print(f"Error: Source directory not found: {source_dir}")
        return False
    
    # Create timestamp for backup folder
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(backup_dir, timestamp)
    
    try:
        # Create backup directory if it doesn't exist
        Path(backup_dir).mkdir(parents=True, exist_ok=True)
        
        # Create directory for this backup
        Path(backup_path).mkdir(parents=True, exist_ok=True)
        
        # Copy entire .data directory
        print(f"Starting backup from {source_dir} to {backup_path}")
        shutil.copytree(source_dir, os.path.join(backup_path, '.data'))
        
        # Count and log total size
        total_size = sum(
            os.path.getsize(os.path.join(dirpath, filename))
            for dirpath, _, filenames in os.walk(backup_path)
            for filename in filenames
        )
        print(f"Backup completed: {total_size / (1024 * 1024):.2f} MB")
        
        # Clean up old backups
        cleanup_old_backups(backup_dir, max_backups)
        return True
        
    except Exception as e:
        print(f"Backup failed: {str(e)}")
        # Try to remove failed backup
        if os.path.exists(backup_path):
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
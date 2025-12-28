#!/usr/bin/env python3

import os
import shutil
import sqlite3
from datetime import datetime
import sys
from pathlib import Path
import argparse
import subprocess
import tempfile
import re

def parse_args():
    """Parse command line arguments"""
    # Build default destination from environment variables
    nas_user = os.getenv('BACKUP_NAS_USER', 'service-backup')
    nas_host = os.getenv('BACKUP_NAS_HOST', '192.168.50.85')
    nas_path = os.getenv('BACKUP_NAS_PATH', '/srv/dev-disk-by-uuid-624a350d-6ef6-4894-8082-22ba887a922d/Backups/expense_flow/')
    default_dest = f'{nas_user}@{nas_host}:{nas_path}'

    parser = argparse.ArgumentParser(description='Backup ExpenseFlow data')
    parser.add_argument('--source', default='.data',
                      help='Source directory to backup (default: .data)')
    parser.add_argument('--dest', default=default_dest,
                      help=f'Destination directory for backups (default: {default_dest}, configure via BACKUP_NAS_USER, BACKUP_NAS_HOST, BACKUP_NAS_PATH env vars)')
    parser.add_argument('--max-backups', type=int, default=int(os.getenv('BACKUP_MAX_BACKUPS', '14')),
                      help='Maximum number of backups to keep (default: 14, configure via BACKUP_MAX_BACKUPS env var)')
    parser.add_argument('--ssh-key', default=os.getenv('BACKUP_SSH_KEY'),
                      help='Path to SSH private key (optional, configure via BACKUP_SSH_KEY env var)')
    return parser.parse_args()

def _is_backup_directory(name: str) -> bool:
    """Check if directory name matches backup timestamp pattern (YYYYMMDD_HHMMSS)"""
    pattern = r'^\d{8}_\d{6}$'
    return bool(re.match(pattern, name))


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


def create_backup(source_dir, backup_dest, max_backups, ssh_key=None):
    """Create a consistent backup of the data directory using rsync"""
    source_path = Path(source_dir)
    if not source_path.is_dir():
        print(f"Error: Source directory not found: {source_dir}")
        return False

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    try:
        # Create temporary directory for SQLite backups
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            print(f"Starting backup from {source_dir} to {backup_dest}")

            # First, handle SQLite databases with proper backup
            for root, _, files in os.walk(source_path):
                root_path = Path(root)
                relative_root = root_path.relative_to(source_path)

                for filename in files:
                    source_item = root_path / filename
                    relative_path = source_item.relative_to(source_path)
                    temp_destination = temp_path / relative_path

                    if source_item.name.endswith((".sqlite3", ".sqlite")):
                        print(f"Backing up SQLite database: {source_item}")
                        _backup_sqlite_file(source_item, temp_destination)
                    elif not source_item.name.endswith((
                        ".sqlite3-wal",
                        ".sqlite3-shm",
                        ".sqlite-wal",
                        ".sqlite-shm",
                    )):
                        # Copy non-SQLite files and skip WAL/SHM files
                        _copy_path(source_item, temp_destination)

            # Build rsync command
            rsync_cmd = ['rsync', '-avz', '--delete']

            if ssh_key:
                rsync_cmd.extend(['-e', f'ssh -i {ssh_key}'])

            # Add timestamp subdirectory to destination
            full_dest = f"{backup_dest.rstrip('/')}/{timestamp}/"
            rsync_cmd.extend([f"{temp_path}/", full_dest])

            print(f"Running rsync: {' '.join(rsync_cmd)}")
            result = subprocess.run(rsync_cmd, capture_output=True, text=True)

            if result.returncode != 0:
                print(f"rsync failed with code {result.returncode}")
                print(f"stderr: {result.stderr}")
                return False

            print(result.stdout)
            print(f"Backup completed successfully to {full_dest}")

            # Cleanup old backups on remote
            cleanup_old_backups(backup_dest, max_backups, ssh_key)
            return True

    except Exception as e:
        print(f"Backup failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def cleanup_old_backups(backup_dest, max_backups, ssh_key=None):
    """Remove old backups keeping only the most recent max_backups"""
    try:
        # Parse remote destination
        if '@' in backup_dest and ':' in backup_dest:
            # Remote SSH destination
            ssh_host, remote_path = backup_dest.split(':', 1)

            # Build SSH command to list only directories
            ssh_cmd = ['ssh']
            if ssh_key:
                ssh_cmd.extend(['-i', ssh_key])
            # Use find to list only directories, then basename to get just the name
            ssh_cmd.extend([ssh_host, f'find {remote_path} -maxdepth 1 -mindepth 1 -type d -exec basename {{}} \\;'])

            result = subprocess.run(ssh_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                print(f"Failed to list remote backups: {result.stderr}")
                return

            # Filter to only backup directories matching timestamp pattern
            all_dirs = [line.strip() for line in result.stdout.split('\n') if line.strip()]
            backups = sorted([d for d in all_dirs if _is_backup_directory(d)])

            if len(backups) > max_backups:
                print(f"Found {len(backups)} backup directories, keeping {max_backups}")
                for backup_to_remove in backups[:-max_backups]:
                    rm_cmd = ['ssh']
                    if ssh_key:
                        rm_cmd.extend(['-i', ssh_key])
                    rm_cmd.extend([ssh_host, f'rm -rf {remote_path.rstrip("/")}/{backup_to_remove}'])

                    print(f"Removing old backup: {backup_to_remove}")
                    result = subprocess.run(rm_cmd, capture_output=True, text=True)
                    if result.returncode != 0:
                        print(f"Failed to remove {backup_to_remove}: {result.stderr}")
            else:
                print(f"Found {len(backups)} backup directories, no cleanup needed")
        else:
            # Local destination
            all_dirs = [d for d in os.listdir(backup_dest)
                       if os.path.isdir(os.path.join(backup_dest, d))]
            # Filter to only backup directories matching timestamp pattern
            backups = sorted([d for d in all_dirs if _is_backup_directory(d)])

            if len(backups) > max_backups:
                print(f"Found {len(backups)} backup directories, keeping {max_backups}")
                for backup_to_remove in backups[:-max_backups]:
                    path_to_remove = os.path.join(backup_dest, backup_to_remove)
                    print(f"Removing old backup: {path_to_remove}")
                    shutil.rmtree(path_to_remove)
            else:
                print(f"Found {len(backups)} backup directories, no cleanup needed")

    except Exception as e:
        print(f"Error during backup cleanup: {str(e)}")

def check_destination_available(backup_dest, ssh_key=None):
    """Check if the backup destination is available"""
    if '@' in backup_dest and ':' in backup_dest:
        # Remote SSH destination
        ssh_host, remote_path = backup_dest.split(':', 1)

        # Test SSH connectivity and directory existence
        ssh_cmd = ['ssh']
        if ssh_key:
            ssh_cmd.extend(['-i', ssh_key])
        ssh_cmd.extend([ssh_host, f'test -d {remote_path} && echo "OK" || mkdir -p {remote_path} && echo "CREATED"'])

        try:
            result = subprocess.run(ssh_cmd, capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                print(f"Error: Cannot access remote backup destination: {backup_dest}")
                print(f"SSH error: {result.stderr}")
                return False

            output = result.stdout.strip()
            if output == "CREATED":
                print(f"Created remote backup directory: {remote_path}")
            elif output == "OK":
                print(f"Remote backup directory exists: {remote_path}")

            return True
        except subprocess.TimeoutExpired:
            print(f"Error: SSH connection timed out to {ssh_host}")
            return False
        except Exception as e:
            print(f"Cannot connect to remote backup destination: {str(e)}")
            return False
    else:
        # Local destination
        parent_dir = os.path.dirname(backup_dest)
        if not os.path.exists(parent_dir):
            print(f"Error: Backup destination parent directory not found: {parent_dir}")
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
    if not check_destination_available(args.dest, args.ssh_key):
        print("Backup aborted: destination not available")
        sys.exit(1)

    # Create backup
    success = create_backup(args.source, args.dest, args.max_backups, args.ssh_key)

    if success:
        print("Backup completed successfully")
        sys.exit(0)
    else:
        print("Backup failed")
        sys.exit(1)

if __name__ == "__main__":
    main()

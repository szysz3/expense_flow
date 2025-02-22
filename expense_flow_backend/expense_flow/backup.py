#!/usr/bin/env python3

import os
import shutil
from datetime import datetime
import sys
from pathlib import Path
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('expense_flow_backup.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

# Configuration
HOME = os.path.expanduser("~")
SOURCE_DIR = os.path.join(HOME, "Projects/expense_flow/expense_flow_backend/.data/serve")
BACKUP_DIR = "/Volumes/backup/expense_flow_backups"
MAX_BACKUPS = 14
DB_FILES = ["receipts.db", "temp_receipts.db"]

def create_backup():
    # Create timestamp for backup folder
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(BACKUP_DIR, timestamp)
    
    try:
        # Create backup directory if it doesn't exist
        Path(BACKUP_DIR).mkdir(parents=True, exist_ok=True)
        Path(backup_path).mkdir(parents=True, exist_ok=True)
        
        # Copy each database file
        for db_file in DB_FILES:
            source_file = os.path.join(SOURCE_DIR, db_file)
            dest_file = os.path.join(backup_path, db_file)
            
            if os.path.exists(source_file):
                shutil.copy2(source_file, dest_file)
                logging.info(f"Successfully backed up {db_file} to {dest_file}")
            else:
                logging.warning(f"Source file {source_file} does not exist")
                
        # Clean up old backups
        cleanup_old_backups()
        
    except Exception as e:
        logging.error(f"Backup failed: {str(e)}")
        sys.exit(1)

def cleanup_old_backups():
    """Remove old backups keeping only the most recent MAX_BACKUPS"""
    try:
        # List all backup directories
        backups = sorted([d for d in os.listdir(BACKUP_DIR) 
                         if os.path.isdir(os.path.join(BACKUP_DIR, d))])
        
        # Remove oldest backups if we have more than MAX_BACKUPS
        while len(backups) > MAX_BACKUPS:
            oldest = backups.pop(0)
            oldest_path = os.path.join(BACKUP_DIR, oldest)
            shutil.rmtree(oldest_path)
            logging.info(f"Removed old backup: {oldest_path}")
            
    except Exception as e:
        logging.error(f"Cleanup failed: {str(e)}")

if __name__ == "__main__":
    create_backup()
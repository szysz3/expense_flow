#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_DIR="${SCRIPT_DIR}/.data"
BACKUP_SCRIPT="${SCRIPT_DIR}/backup.py"

if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "Error: Backup script not found at $BACKUP_SCRIPT"
    exit 1
fi

chmod +x "$BACKUP_SCRIPT"

(crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT") | crontab -

(crontab -l 2>/dev/null; echo "0 1 * * * $BACKUP_SCRIPT --source '$SOURCE_DIR' >> $HOME/expense_flow_backup.log 2>&1") | crontab -

echo "Backup job scheduled successfully:"
echo "- Script: $BACKUP_SCRIPT"
echo "- Log file: $HOME/expense_flow_backup.log"
echo "- Runs daily at 1 AM"

echo -e "\nCurrent crontab:"
crontab -l
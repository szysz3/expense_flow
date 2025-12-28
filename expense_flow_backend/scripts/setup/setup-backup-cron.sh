#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
SOURCE_DIR="${PROJECT_ROOT}/.data"
BACKUP_SCRIPT="${PROJECT_ROOT}/scripts/backup.py"

if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "Error: Backup script not found at $BACKUP_SCRIPT"
    exit 1
fi

chmod +x "$BACKUP_SCRIPT"

# Get configuration from environment or use defaults
BACKUP_NAS_USER="${BACKUP_NAS_USER:-service-backup}"
BACKUP_NAS_HOST="${BACKUP_NAS_HOST:-192.168.50.85}"
BACKUP_NAS_PATH="${BACKUP_NAS_PATH:-/srv/dev-disk-by-uuid-624a350d-6ef6-4894-8082-22ba887a922d/Backups/expense_flow/}"
BACKUP_DEST="${BACKUP_NAS_USER}@${BACKUP_NAS_HOST}:${BACKUP_NAS_PATH}"

(crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT") | crontab -

# Add environment variables to cron job
CRON_JOB="0 1 * * * BACKUP_NAS_USER='$BACKUP_NAS_USER' BACKUP_NAS_HOST='$BACKUP_NAS_HOST' BACKUP_NAS_PATH='$BACKUP_NAS_PATH' $BACKUP_SCRIPT --source '$SOURCE_DIR' >> $HOME/expense_flow_backup.log 2>&1"

(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Backup job scheduled successfully:"
echo "- Script: $BACKUP_SCRIPT"
echo "- Source Directory: $SOURCE_DIR"
echo "- Destination: $BACKUP_DEST"
echo "- Log file: $HOME/expense_flow_backup.log"
echo "- Runs daily at 1 AM"
echo ""
echo "Configuration (set these environment variables before running this script to customize):"
echo "  BACKUP_NAS_USER=$BACKUP_NAS_USER"
echo "  BACKUP_NAS_HOST=$BACKUP_NAS_HOST"
echo "  BACKUP_NAS_PATH=$BACKUP_NAS_PATH"
echo ""
echo "Note: Backup runs on host machine using rsync over SSH to NAS"
echo "Ensure SSH key for ${BACKUP_NAS_USER}@${BACKUP_NAS_HOST} is configured in ~/.ssh"
echo -e "\nCurrent crontab:"
crontab -l
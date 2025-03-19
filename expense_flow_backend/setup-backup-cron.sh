#!/bin/bash
set -e

LOG_FILE="/app/.data/backup.log"

touch "$LOG_FILE"

(crontab -l 2>/dev/null; echo "0 1 * * * cd /app && python -m expense_flow.backup --source=/app/.data --dest=/mnt/sdcard/expense_flow_backups --max-backups=14 >> \"$LOG_FILE\" 2>&1") | crontab -

cron

echo "Backup cron job configured"
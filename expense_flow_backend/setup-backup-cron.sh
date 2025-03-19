#!/bin/bash
set -e

LOG_FILE="/app/.data/backup.log"

touch "$LOG_FILE"
chown appuser:appuser "$LOG_FILE"

cat > /etc/cron.d/expense-backup << EOF
# Run backup every night at 1 AM
0 1 * * * appuser cd /app && python -m expense_flow.backup --source=/app/.data --dest=/mnt/sdcard/expense_flow_backups --max-backups=14 >> "$LOG_FILE" 2>&1
EOF

chmod 0644 /etc/cron.d/expense-backup

exec service cron start -fW
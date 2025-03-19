#!/bin/bash

# Create a new crontab file
cat > /tmp/expense-backup-cron << EOF
# Run backup every night at 1 AM
0 1 * * * cd /app && python -m expense_flow.backup --source=/app/.data --dest=/mnt/sdcard/expense_flow_backups --max-backups=14 >> /var/log/cron.log 2>&1
EOF

# Install the new crontab
crontab /tmp/expense-backup-cron

# Start cron service
service cron start

# Remove temp file
rm /tmp/expense-backup-cron
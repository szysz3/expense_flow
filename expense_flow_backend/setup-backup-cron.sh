#!/bin/bash
set -e

# Ensure log file exists and has correct permissions
touch /var/log/cron.log
chown appuser:appuser /var/log/cron.log

# Create a new crontab file
cat > /etc/cron.d/expense-backup << EOF
# Run backup every night at 1 AM
0 1 * * * appuser cd /app && python -m expense_flow.backup --source=/app/.data --dest=/mnt/sdcard/expense_flow_backups --max-backups=14 >> /var/log/cron.log 2>&1
EOF

# Set proper permissions for the cron job file
chmod 0644 /etc/cron.d/expense-backup

# Start cron service in foreground
exec service cron start -f
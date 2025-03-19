#!/bin/bash
set -e

# Setup the backup cron job
/app/setup-backup-cron.sh

# Start the API service
exec python -m expense_flow.api.main --host 0.0.0.0 --port 8000
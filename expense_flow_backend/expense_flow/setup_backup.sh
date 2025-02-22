#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 /path/to/backup_script.py"
    exit 1
fi

BACKUP_SCRIPT="$1"

# Verify if the script exists
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "Error: Backup script not found at $BACKUP_SCRIPT"
    exit 1
fi

# Determine Python path
PYTHON_PATH=$(which python3)

# Make the Python script executable
chmod +x "$BACKUP_SCRIPT"

# Add to crontab (running at midnight daily)
# Using full paths and setting PATH environment variable
(crontab -l 2>/dev/null; echo "PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
* * * * * $PYTHON_PATH $BACKUP_SCRIPT") | crontab -

# Verify crontab entry
echo "Crontab entry added. Current crontab contents:"
crontab -l
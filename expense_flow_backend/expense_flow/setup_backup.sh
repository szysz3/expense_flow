#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 /path/to/backup_script.py"
    exit 1
fi

BACKUP_SCRIPT="$1"
LABEL="com.user.backup"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"

# Verify if the script exists
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "Error: Backup script not found at $BACKUP_SCRIPT"
    exit 1
fi

# Get absolute path of the backup script
BACKUP_SCRIPT_ABS=$(realpath "$BACKUP_SCRIPT")

# Determine Python path
PYTHON_PATH=$(which python3)
if [ -z "$PYTHON_PATH" ]; then
    echo "Error: Python 3 not found"
    exit 1
fi

# Make the Python script executable
chmod +x "$BACKUP_SCRIPT"

# Create the launchd plist file
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>${PYTHON_PATH}</string>
        <string>${BACKUP_SCRIPT_ABS}</string>
    </array>
    
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>0</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    
    <key>StandardErrorPath</key>
    <string>${HOME}/Library/Logs/${LABEL}.err</string>
    
    <key>StandardOutPath</key>
    <string>${HOME}/Library/Logs/${LABEL}.out</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

# Set proper permissions for the plist file
chmod 644 "$PLIST_PATH"

# Unload the job if it already exists
launchctl unload "$PLIST_PATH" 2>/dev/null

# Load the new job
launchctl load "$PLIST_PATH"

# Verify the job is loaded
if launchctl list | grep -q "${LABEL}"; then
    echo "LaunchD job successfully installed and loaded."
    echo "Plist file created at: $PLIST_PATH"
    echo "Logs will be written to:"
    echo "  - ${HOME}/Library/Logs/${LABEL}.out"
    echo "  - ${HOME}/Library/Logs/${LABEL}.err"
else
    echo "Error: Failed to load LaunchD job"
    exit 1
fi
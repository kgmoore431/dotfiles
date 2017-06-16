#!/bin/bash
set -e
# Backup the Current prefs for sublime 3 and re-link the user preferences to this repo

subl_settings_path="${HOME}/Library/Application Support/Sublime Text 3/Packages/"

if [[ -d "${subl_settings_path}/User" ]]; then
    tar -cHvzf "sublime3_user_settings_$(date +%F).backup.tgz" -C "${subl_settings_path}" User/



else
    echo "No existing user settings"
fi

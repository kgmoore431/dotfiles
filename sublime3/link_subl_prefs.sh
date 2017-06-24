#!/bin/bash
set -e
# Backup the Current prefs for sublime 3 and re-link the user preferences to this repo

subl_settings_path="${HOME}/Library/Application Support/Sublime Text 3/Packages/"
mkdir -p "${subl_settings_path}"

my_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -d "${subl_settings_path}/User" ]]; then
    backup_file="sublime3_user_settings_$(date +%F).backup.tgz"
    echo "Backing Up current prefs as: ${backup_file}"

    tar -cHzf "${backup_file}" -C "${subl_settings_path}" User/
fi

ln -Fis "$my_dir/Packages/User" "${subl_settings_path}"

echo "Don't forget to pip install flake8 and pep8 for code linting"

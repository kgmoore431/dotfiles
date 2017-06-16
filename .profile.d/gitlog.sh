#!/bin/bash

#Grab all of my commits in the current repo for the last 1month and give a quick summary.
function git_mylog() {
    git log --author="$(git config user.name)" --after $(date -v-1m +%F) --format="%Cred%h%Creset %ad %cn %Cblue%s%Creset" --date=short --reverse
}

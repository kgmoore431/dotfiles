#!/bin/bash
### Git Stuff ###
# Do a git pull for all git repos  in a directory
function pull_all {
    for x in $(\ls -1d */); do
        if [[ -d $x/.git ]]; then
            pushd $x
            pwd
            git pull origin
            popd
        fi
    done
}

function all-repo-clean { # clean out merged branches {{{
  for i in */.git/; do
    pushd ${i%.git/} > /dev/null 2> /dev/null
    echo $(pwd)
    git pull
    git branch --merged | grep -v '^\*' | grep -v 'rc/branch/'| grep -vE '^\s+master\s*$' | grep -vE '^\s+gh-pages\s*$'
    popd > /dev/null
  done
} # }}}


function parse_git_branch () {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"
LTBLUE="\033[1;34m"

function git_color {
  local git_status="$(git status 2> /dev/null)"

  if [[ $git_status =~ "working tree clean" ]]; then
    echo -e $GREEN
  elif [[ $git_status =~ "Your branch is ahead of" ]]; then
    echo -e $YELLOW
  elif [[ $git_status =~ "nothing added to commit but untracked" ]]; then
    echo -e $YELLOW
  elif [[ $git_status =~ "Changes to be committed" ]]; then
    echo -e $YELLOW
  elif [[ $git_status =~ "Changes not staged for commit" ]]; then
    echo -e $RED
  else
    echo -e $NO_COLOR
  fi
}

# brew bash completion for git
# Make sure you have done:  brew install git && brew install bash-completion
if [ -f `brew --prefix`/etc/bash_completion ]; then
    . `brew --prefix`/etc/bash_completion
fi


# Set command prompt to include branch names & Status when in a git folder
PS1="\\[\[$LTBLUE\]\h\[$NO_COLOR\]:\w\[\$(git_color)\]\$(parse_git_branch)\[$NO_COLOR\]\$ "


### Git Stuff ###

#Grab all of my commits in the current repo for the last 1month and give a quick summary.
function git_mylog() {
    git log --author="$(git config user.name)" --after $(date -v-1m +%F) --format="%Cred%h%Creset %ad %cn %Cblue%s%Creset" --date=short --reverse
}

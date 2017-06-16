#!/bin/bash

alias ll='ls -al'
alias ltr='ls -altr'
alias ltrd='ls -altr |tail -10'
alias resource='source ~/.bash_profile'

lcase_inits="$(tr [:upper:] [:lower:] <<< ${INITIALS})"

alias ${lcase_inits}now='echo "${INITIALS} `date +"%F %T"` <-- On clipboard"; echo "${INITIALS} `date +"%F %T"`" |pbcopy'
alias devsrc='for i in $(find ${GR_HOME}/engineering/bash -type f -o -type l); do source $i;done'
alias opssrc='for i in $(find ${GR_HOME}/ops-tools/bash/grnds-profile.d/ -type f -o -type l); do source $i;done'

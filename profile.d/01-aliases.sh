#!/bin/bash

alias ll='ls -al'
alias ltr='ls -altr'
alias ltrd='ls -altr |tail -10'
alias resource='source ~/.bash_profile'
alias ops='cd ${CORP_HOME}/it-ops'
alias web='cd ${CORP_HOME}/aurora-web'

function gamfiles () {
     gam user "${1}" show filelist todrive id alternatelink name owners shared
}


function gamtermdate () {
    gam info user "${1}" |grep "Last login" |cut -f2 -d: |cut -f1 -d"T"
}


function find_receipt () {
    amt="$1"
    the_receipt="$(grep -r --include="*.html" ${amt} *|head -1 |cut -f1 -d:)"
    receipt_dir="$(dirname "${the_receipt}")"
    open "${receipt_dir}"
}

# #web = test.aurora-staging.com
# alias stage_test='gsutil -m -h "Cache-Control:public,max-age=60" rsync  -x "\.DS_Store$|.*/\.DS_Store$" -c -d -R /Users/kmoore/src/aurora/aurora-web/published gs://test.aurora-staging.com/; echo "Pushed to: https://test.aurora-staging.com"'

# #test = web.aurora-staging.com
# alias stage_web='gsutil -m  -h "Cache-Control:public,max-age=60" rsync -x "\.DS_Store$|.*/\.DS_Store$" -c -d -R /Users/kmoore/src/aurora/aurora-web/published/ gs://aurora-staging-site/ ; echo "Pushed to: https://web.aurora-staging.com"'

# #Staging to Prod
# alias prod_web='gsutil -m -h "Cache-Control:public,max-age=86400" rsync  -x "robots.txt" -c -d -R gs://aurora-staging-site/ gs://aurora-tech-site/; ; echo "Pushed to: https://aurora.tech"'

alias tf='terraform'
alias mydrive='cd "/Volumes/GoogleDrive/My Drive"'
alias get_headshots='gam create datatransfer headshots@aurora.tech gdrive kevin@aurora.tech privacy_level shared,private'
alias headshots='cd "/Volumes/GoogleDrive/My Drive/headshots@aurora.tech"'

alias speed_check='speedtest --server 1749'
alias chromecode='gam user chrome show backupcodes'
alias asset_tag='echo "TBD-$(uuidgen |cut -f1 -d-)" |pbcopy'

lcase_inits="$(tr [:upper:] [:lower:] <<< ${INITIALS})"

alias ${lcase_inits}now='echo "${INITIALS} `date +"%F %H:%M %Z"` <-- On clipboard"; echo "${INITIALS} `date +"%F %H:%M %Z"`" |pbcopy'
alias kgnow="${lcase_inits}now"
alias devsrc='for i in $(find ${CORP_HOME}/engineering/bash -type f -o -type l); do source $i;done'
alias opssrc='for i in $(find ${CORP_HOME}/ops-tools/bash/grnds-profile.d/ -type f -o -type l); do source $i;done'

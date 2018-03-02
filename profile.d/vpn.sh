alias vpn='sudo ipsec stop && sudo ipsec start && sleep 1 && sudo ipsec up grnds-sfo'
alias production='sudo ipsec stop && sudo ipsec start && sleep 1 && sudo ipsec up production && aws-environment production'
alias uat='sudo ipsec stop && sudo ipsec start && sleep 1 && sudo ipsec up uat && aws-environment uat'
alias development='sudo ipsec stop && dev-environment'

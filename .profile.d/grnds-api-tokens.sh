#!/bin/bash

#API Token management

export ALL_TOKENS=$(find ${HOME}/.api_tokens -maxdepth 1 -type f -name "${GR_USERNAME}-*.gpg" | perl -pe "s|^${HOME}/.api_tokens/${GR_USERNAME}-(.*)\.gpg|\1|g" | xargs echo)


function gr_load_token {
  local env_file="${HOME}/.api_tokens/${GR_USERNAME}-${1}.gpg"
  if [ "$1" = '-h' -o "$1" = '-?' ]; then
    echo "Usage: $FUNCNAME [ -h ] [ token_to_use ]" 1>&2
  elif [ ! -f $env_file ]
  then
    echo "Not found: token file $env_file" 1>&2
  else
    echo ${1}
    # export AWS_ENVIRONMENT=$1
    source /dev/stdin <<-EOF
$(gpg --no-tty --quiet -o - ${env_file})
EOF
  fi
}

_gr-token-completer()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "$ALL_TOKENS" -- $cur) )
}
complete -F _gr-token-completer gr_load_token

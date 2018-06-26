#!/bin/bash

# The next line updates PATH for the Google Cloud SDK.
[[ -e "${HOME}/google-cloud-sdk/path.bash.inc" ]] && source "${HOME}/google-cloud-sdk/path.bash.inc"

# The next line enables shell command completion for gcloud.
[[ -e "${HOME}/google-cloud-sdk/completion.bash.inc" ]] && source "${HOME}/google-cloud-sdk/completion.bash.inc"


function gcp_environment {
    if [ -z "$1" ]; then
        echo ${GCP_ENVIRONMENT:-'Provide an argument to set it'}
    elif [ "$1" = '-h' -o "$1" = '-?' ]; then
        echo "Usage: $0 [ -h ] [ environment_to_use ]" 1>&2
    else
        export GCP_ENVIRONMENT=$1
        gcloud config configurations activate "${GCP_ENVIRONMENT}"
    fi
}

export -f gcp_environment

_complete_gcp_environs ()
{
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    comp_gcp_environs=$(gcloud config configurations list | tail -n +2 |cut -f1 -d' ')
    COMPREPLY=( $(compgen -W "${comp_gcp_environs}" -- $cur))
    return 0
}
complete -F _complete_gcp_environs gcp_environment


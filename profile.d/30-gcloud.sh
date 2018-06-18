
# The next line updates PATH for the Google Cloud SDK.
[[ -e "${HOME}/google-cloud-sdk/path.bash.inc" ]] && source "${HOME}/google-cloud-sdk/path.bash.inc"

# The next line enables shell command completion for gcloud.
[[ -e "${HOME}/google-cloud-sdk/completion.bash.inc" ]] && source "${HOME}/google-cloud-sdk/completion.bash.inc"

# export GOOGLE_APPLICATION_CREDENTIALS="/Users/kmoore/.config/gcloud/legacy_credentials/kevin@aurora.tech/corp-it-151690da7169.json"

function gswitch {
    gcloud config configurations activate $1
}

export ALL_GCONF="$(gcloud config configurations list |cut -f1 -d" " |awk 'NR>1')"

_my-gconf-completer()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "$ALL_GCONF" -- $cur) )
}
complete -F _my-token-completer my_load_token

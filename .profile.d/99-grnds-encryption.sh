#!/bin/bash

#Encrypt / decrypt functions

function encrypt_eng {
    RECIPIENTS=$(find "${CORP_HOME}engineering/gpg/public/dev-ops" -type f -exec basename {} \;| sed -e's/^/-r /' | tr '\n' ' ' | sed -e's/.pub//g')
    for file in "$@"; do
        # shellcheck disable=SC2086
        gpg -e ${RECIPIENTS} --trust-model always "$file"
    done

}
export -f encrypt_eng


function encrypt_analyst {
    RECIPIENTS=$(find "${CORP_HOME}analytics/credentials/gpg/analyst" -type f -exec basename {} \;| sed -e's/^/-r /' | tr '\n' ' ' | sed -e's/.pub//g')
    for file in "$@"; do
        # shellcheck disable=SC2086
        gpg -e ${RECIPIENTS} --trust-model always "$file"
    done

}
export -f encrypt_analyst

function get_control_group {
    # fetch keys from published control-group list
    KEYS=$(curl -s https://consultingmd.github.io/dangernoodle/control-group | awk '{print $1}')
    # add -r's and single-line them
    # shellcheck disable=SC2086
    RECIPS=$(perl -pe 's/\b(\w+)\b/-r $1/g' <<< $KEYS)
    echo "${RECIPS}"
}

function get_it_group {
    # fetch keys from published it-group list
    KEYS=$(curl -s https://consultingmd.github.io/dangernoodle/it-group | awk '{print $1}')
    # add -r's and single-line them
    # shellcheck disable=SC2086
    RECIPS=$(perl -pe 's/\b(\w+)\b/-r $1/g' <<< $KEYS)
    echo "${RECIPS}"
}

function encrypt_control {
    RECIPIENTS="$(get_control_group)"
    if [[ -z "${RECIPIENTS}" ]]; then
      echo "Error loading control-group. File not encrypted."
    else
        for file in "$@"; do
            # shellcheck disable=SC2086
            gpg -e ${RECIPIENTS} --trust-model always "$file"
        done
    fi
}
export -f encrypt_control

function encrypt_it {
    GR_CONTROL_GROUP="$(get_control_group)"
    GR_IT_GROUP="$(get_it_group)"
    if [[ -z "${GR_CONTROL_GROUP}" ]]; then
        echo "Error loading control-group. File not encrypted."
    else
        if [[ -z "${GR_IT_GROUP}" ]]; then
            echo "Error Loading it-group. File not encrypted."
        else
            RECIPIENTS="${GR_IT_GROUP} ${GR_CONTROL_GROUP}"
            for file in "$@"; do
                # shellcheck disable=SC2086
                gpg -e ${RECIPIENTS} --trust-model always "$file"
            done
        fi
    fi
}

export -f encrypt_it

GPG_TTY=$(tty)
export GPG_TTY

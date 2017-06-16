#!/bin/bash

#Gets the owner info based on having an ssh fingerprint on your system clipboard

function gr-whodunit {
    if [[ `uname` == 'Darwin' ]]; then
       FINGERPRINT=`pbpaste`
    else
       FINGERPRINT=`xsel -b`
    fi
    find ${GR_HOME}/engineering/ssh/ -name '*.pub' -type f -exec ssh-keygen -lf {} \; |grep -i "${FINGERPRINT}"
}


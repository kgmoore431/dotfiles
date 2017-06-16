#!/bin/bash

# NOTE: Make sure your system is setup for the mail cli app to be able to use
#   your gmail credentials and mail server config
#   also requires that $GR_GPGKEY_ADDRESS be declared in your bash profile
#   See also: http://eng.grandrounds.com/blog/2015/06/19/securely-transmitting-credentials-from-the-commandline-with-osx-and-gmail/

function send_creds {
    if [[ $# -ne 3 ]]; then
        echo "error: usage [filename user_email cred_type]"
        return 1
    fi
    file="$1"
    user_email="$2"
    cred_type="$3"

    gpg -q -e -r "${GR_GPGKEY_ADDRESS}" -r "${user_email}" --trust-model always "${file}"
    if [[ $? -ne 0 ]]; then
        echo ""
        echo "ERROR - Encrypting credentials"
        echo ""
        return 2
    fi
    echo "Emailing credentials to: ${user_email}"
    uuencode ${file}.gpg ${file}.gpg | mail -b "${GR_GPGKEY_ADDRESS}"  -s "${cred_type} Credentials" "${user_email}"
}

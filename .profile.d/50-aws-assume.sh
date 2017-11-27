#!/bin/bash

function my_assume_role_newacct {
    acct_id="$1"
    if [[ "$AWS_ENVIRONMENT" == "operations" ]]; then
        my_role="arn:aws:iam::${acct_id}:role/OrganizationAccountAccessRole"

        role_creds=$(aws sts assume-role --role-arn "${my_role}" --role-session-name "${CORP_USERNAME}")

        eval $(jq -r '.Credentials|
        "export AWS_ACCESS_KEY_ID=" + .AccessKeyId,
        "export AWS_SECRET_ACCESS_KEY=" + .SecretAccessKey,
        "export AWS_SESSION_TOKEN=" + .SessionToken' <<< "${role_creds}")
        eval "export AWS_ENVIRONMENT=${acct_id}"

        echo "AWS Access Keys and SessionToken set for assumed role. Session will expire in ~1hr"
    else
        echo "echo \"ERROR - AWS_ENVIRONMENT must be operations\""
    fi
}
export -f my_assume_role_newacct


function my_assume_role_saml {
    acct_id=[MASTER_AWS_ACCOUNT_NUMBER]


    my_role="arn:aws:iam::${acct_id}:role/qa-saml-role"
    my_principal="arn:aws:iam::${acct_id}:saml-provider/Google-QA-SAML"

    role_creds=$(aws sts assume-role-with-saml --role-arn "${my_role}" --principal-arn "${my_principal}" --role-session-name "${CORP_USERNAME}")

    eval $(jq -r '.Credentials|
    "export AWS_ACCESS_KEY_ID=" + .AccessKeyId,
    "export AWS_SECRET_ACCESS_KEY=" + .SecretAccessKey,
    "export AWS_SESSION_TOKEN=" + .SessionToken' <<< "${role_creds}")
    eval "export AWS_ENVIRONMENT=${acct_id}"

    echo "AWS Access Keys and SessionToken set for assumed role. Session will expire in ~1hr"
}

#!/bin/bash
set -e
if [ -z "$1" ];
then
    echo "$0 requires filename as an argument"
    exit
fi

. $HOME/.bashrc

BUCKET="gr-development-temp"
RANDO=$(< /dev/urandom tr -dc A-Z-a-z-\0-9 | head -c16)
SHARE_PATH="$RANDO/${1##*/}"
S3_URL="s3://$BUCKET/$SHARE_PATH"
HTTP_URL="https://$BUCKET.s3.amazonaws.com/$SHARE_PATH"

aws-environment development
aws s3 cp --acl=public-read $1 $S3_URL
echo "uploaded to $HTTP_URL"
echo $HTTP_URL | xsel -ib

function gr-load-root-key {
  if [ -z "$1" ] && [ -z "$AWS_ENVIRONMENT" ];
  then
    echo "$FUNCNAME requires an AWS_ENVIRONMENT or environment argument"
    return
  fi
  if [ -n "$1" ]; then
      ENVIRONMENT="$1"
  else
      ENVIRONMENT="$AWS_ENVIRONMENT"
  fi
  secret_key=$GR_HOME/engineering/ssh/private/aws-grnds-$ENVIRONMENT.pem.gpg
  if [ "$1" = '-h' -o "$1" = '-?' ] ;
  then
    echo "Usage: $0 [ -h ] [ optional environment_to_use or AWS_ENVIRONMENT used ]" 1>&2
  elif [ ! -f $secret_key ]
  then
    echo "File Not found: $secret_key" 1>&2
  else
    tmp_file=/tmp/$ENVIRONMENT
    gpg --use-agent -d $secret_key > $tmp_file
    chmod 600 $tmp_file
    ssh-add $tmp_file
    rm $tmp_file
  fi
}

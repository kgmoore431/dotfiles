#!/bin/bash
export ALL_ENVIRONMENTS=$(find ${HOME}/.aws-creds -maxdepth 1 -type f -name "${GR_USERNAME}-*.gpg" | perl -pe "s|^${HOME}/.aws-creds/${GR_USERNAME}-(.*)\.gpg|\1|g" | xargs echo)
export AWS_DEFAULT_REGION=us-east-1

function warehouse-environment {
  # Always remove, so you can use legacy warehouse-environment for the production
  # setup.
  $(env | sed -n '/REDSHIFT/s;\(^.*\)=.*$;unset \1;p')

  local warehouse_env="${GR_HOME}/engineering/credentials/aws/${AWS_ENVIRONMENT}/warehouse.gpg"
  if [ -f "$warehouse_env" ] ; then
    $(gpg --use-agent --no-tty --quiet -o - ${warehouse_env})
  fi
}

function aws-environment {
  local env_file="${HOME}/.aws-creds/${GR_USERNAME}-${1}.gpg"
  if [ -z "$1" ];
  then
    echo ${AWS_ENVIRONMENT:-'Provide an argument to set it'}
  elif [ "$1" = '-h' -o "$1" = '-?' ] ;
  then
    echo "Usage: $0 [ -h ] [ environment_to_use ]" 1>&2
  elif [ ! -f $env_file ]
  then
    echo "Not found: credential file $env_file" 1>&2
  else
    export AWS_ENVIRONMENT=$1
    source /dev/stdin <<-EOF
$(gpg --use-agent --no-tty --quiet -o - ${env_file})
EOF
    warehouse-environment
  fi
}

alias gr-aws-environment=aws-environment
alias gr-env=aws-environment

_gr-aws-completer()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "$ALL_ENVIRONMENTS" -- $cur) )
}

hash complete 2>/dev/null && complete -F _gr-aws-completer aws-environment

function aws-ssh {
  if [ -z "$1" ];
  then
    echo "Specifiy which host you are looking for in ${AWS_ENVIRONMENT:-'You must run aws-environment first.'}"
    return
  elif [ -z "$AWS_ENVIRONMENT" ] ;
  then
      echo "${AWS_ENVIRONMENT:-'You must run aws-environment first.'}"
      return
  elif [ "$1" = '-h' -o "$1" = '-?' ] ;
  then
    echo "Usage: $0 [ -h ] [ host to find ]" 1>&2
  else
    HOST=$(aws ec2 describe-instances | grep Value | egrep -e "[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}" | grep "$1" | sort -u | perl -pe 's/\s+".+":\s+"(.*)",\s+/$1/;')
      echo "$HOST"
      HOST=${HOST}.${AWS_ENVIRONMENT}
      read -p "SSH to ${HOST} (y/n)? " -n 1 -r
      echo    # (optional) move to a new line
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
          ssh "$HOST"
      fi
  fi

}

# easy way to monitor AWS status pages for changes
# output is "servicename: md5sum" for the named service status RSS
function aws-service-stat {
  SERVICE=$1
  if [ "x$SERVICE" == "x" ] ; then
    echo "usage: echo \$(date) \$(aws-service-stat ec2) \$(aws-service-stat dynamodb) \$(aws-service-stat autoscaling)"
    return 1
  fi
  curl -s "http://status.aws.amazon.com/rss/${SERVICE}-us-east-1.rss" | grep -v '<pubDate>' | grep -v '<updated>' | md5sum | awk "{print \"$SERVICE:\",\$1}"
}

# check iowait and cpusteal for most-recent CFN instances
function aws-check-instance-health {
    STACK_NAME=$(aws cloudformation describe-stacks | jq -r .Stacks[0].StackName)
    echo "Fetching instances for $STACK_NAME"
    for sys in $(aws cloudformation get-template --stack-name "$STACK_NAME" | jq -r .TemplateBody.Resources[].Properties.Name | grep -v null | grep -v vpngw | sort); do
        echo $(ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$sys" "top -b -n5 -d0.1 | grep %Cpu | tail -1 | perl -pe 's/.*(\d+\.\d) wa,.*(\d+\.\d) st/wait: \$1 steal: \$2/'") sys: "$sys"
    done
}


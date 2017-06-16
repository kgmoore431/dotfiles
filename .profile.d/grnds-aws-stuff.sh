## AWS Cloudformation helpers

# function get_cfn_json {
# Replaced by code in engineering/bin
#     for stack in `aws cloudformation list-stacks | egrep -B6 'CREATE_COMPLETE|UPDATE_COMPLETE'|grep 'TemplateDescription' | awk '{print $NF}'|tr -d "\","`; do
#         aws s3 cp s3://grnds-${AWS_ENVIRONMENT}-cloud-formation-stack-json/ /tmp/ --recursive --exclude "*" --include "${stack}*";
#     done
# }


function get_cfn_stack_error {
    if [[ $# -ne 1 ]]; then
        echo "error: usage get_cfn_stack_error [stackname]"
        return 1
    fi
    mystack="${1}";
    if [[ `uname` == 'Darwin' ]]; then
        mybase='base64 -D';
    else
        mybase='base64 -d';
    fi;
    aws cloudformation describe-stack-events --stack-name ${mystack} | grep 'WaitCondition received failed message' |cut -f3 -d:|cut -f2 -d' '|tr -d "'"|${mybase}|gzip -d
}


# AWS CLI
complete -C aws_completer aws

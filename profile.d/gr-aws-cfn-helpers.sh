#!/bin/bash
# FIXME: should work for stacks and racks. Current defaults lean to racks,
#       filter for version depends on rack
# FIXME: Rack diff should actually diff json, generate nice output; on a good day,
#       it should post diff gist to github using gist package

_gr-metal-dir() {
  toss=false
  if [ "-f" == "$1" ] ; then    # Get your fresh directory here
    toss=true;  shift
  fi

  local dir="/tmp/metal/${AWS_ENVIRONMENT}/$1"
  if $toss ; then
    rm -rf "${dir}"
  fi
  mkdir -p "$dir"
  echo "${dir}"
}

_gr-archive-folder() {
  local rack=${1:-$(gr-get-rack)}
  echo "s3://grnds-${AWS_ENVIRONMENT}-cloud-formation-stack-json/$rack/$(gr-get-deployed-rack-version $rack)"
}

gr-get-deployed-rack-version() {
  local rack=${1:-$(gr-get-rack)}
  aws cloudformation get-template --stack-name ${rack} | sed -n '
      /"Description": "GR-Rack-'"${AWS_ENVIRONMENT}"' run/{
        s/.* at \(.*\)", *$/\1/p
        q
      }
    '
}

gr-get-cfn-json() {
  local stack=${1:-$(gr-get-rack)}

  log "Getting our active definition of $stack"
  aws s3 sync $(_gr-archive-folder $stack) $(_gr-metal-dir -f archive) 1>&2

  echo $(_gr-metal-dir archive)
}

# We can't compare against these, since they get massively reordered
# and new keys added as they get processed. Someday?
gr-get-cfn-template() {
  actuals="$(_gr-metal-dir actuals)"
  for stack in $(gr-get-rack -a) ; do
    log "Getting template for $stack"
    aws cloudformation get-template --stack-name ${stack} > "$actuals/$stack.json"
  done
}

gr-get-rack() {
  local show='fgrep -v "Shard"'
  local usage="Usage: gr-get-rack [ -a ]

Gets list of racks for your AWS_ENVIRONMENT.

Options:
  -a      include shards (implies -k)
  -k      don't fail if more than one result
  -x      exclude rollbacks
"

  local stack_exists="CREATE_COMPLETE UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE"
  local check_count=true

  while [ $# -gt 0 ] ; do
    local option="$1"
    shift
    case "$option" in
    -a ) show='cat'
         check_count=false
         ;;
    -k ) check_count=false ;;
    -x ) stack_exists="CREATE_COMPLETE UPDATE_COMPLETE";;
    * ) echo "$usage" ; return 1 ;;
    esac
  done

  local racks=$(aws cloudformation list-stacks --stack-status-filter ${stack_exists} |\
      awk '/StackName.*gr-rack/ {print $NF}' |\
      tr -d "\"," |\
      eval $show)

  if $check_count ; then
    count=$(echo "${racks}" | wc -l)
    if [ -n "$count" -a "$count" -gt 1 ] ; then
      log "Too many racks found: ${racks}; check using gr-get-rack -k"
      return 1
    fi
  fi
  echo "$racks"
}

base64_decompress() {
  if [[ `uname` == 'Darwin' ]]; then
    echo "base64 -D";
  else
    echo "base64 -d";
  fi;
}

log() {
  >&2 echo "$*"
}

gr-construct-request-json() {
  local rack=${1:-$(gr-get-rack)}
  local template=${2:-rack-template}
  ./submit-cfn-template.rb -s "$rack" -n -d $(_gr-metal-dir pending) ./template/rack-template.json.erb ${AWS_ENVIRONMENT} >/dev/null
  _gr-metal-dir pending
}

gr-push() {
  local array=$1
  local value=$2

  eval "$array"'=("${'"$array"'[@]}" "'"$value"'" )'
}

gr-pop() {
  local array=$1
  local last_entry="$array"'[${#'"$array"'[@]}-1]'
  eval echo '${'$last_entry'}'
  eval "unset $last_entry"
}

_gr_push_e() {
  gr-push _push_e_stack $(expr "$-" : '.*e')
  set -e
}

_gr_pop_e() {
  popped=$(gr-pop _push_e_stack)
  if [ -n "$popped" ] ; then
    case $popped in
    0)  set +e ;;
    *)  set -e ;;
    esac
  fi
}

gr-rack-diff() {
  _gr_push_e
  local rack="$(gr-get-rack)"

  log "constructing local json from templates for ${rack}"
  log '----------'
  local request_dir=$(gr-construct-request-json $rack)

  log
  log "retrieving latest running rack"
  log '----------'
  local actual_dir=$(gr-get-cfn-json $rack)

  _gr_pop_e

  gr-rack-diff-usage() { echo "gr-rack-diff: [-m] [-g]" >&2; return 1; }

  local format="diff"

  local OPTIND opt
  while getopts "mgd:" opt; do
    case "${opt}" in
    m) format="echo" ;;
    g) format='gist' ;;
    *) gr-rack-diff-usage ;;
    esac
  done
  shift $((OPTIND-1))

  case $format in
  diff* ) diff -r $@ ${actual_dir} ${request_dir} ;;
  echo )  echo "${actual_dir}" "${request_dir}" ;;
  gist )  gr-gist-diff-dirs "${AWS_ENVIRONMENT} ${rack} proposed differences" ${actual_dir} ${request_dir} ;;
  * )     log "Format '${format}' unknown"
  esac
}

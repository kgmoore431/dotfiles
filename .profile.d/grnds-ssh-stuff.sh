

#Removes a host entry line from known_hosts by line number
function unknow {
    if [[ -n "$1" ]]; then
        sed -i bak "$1d" ~/.ssh/known_hosts
    else
        echo "err - need line number to unknow"
    fi
}

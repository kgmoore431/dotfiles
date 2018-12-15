

activate() {
    source ~/.virtualenv/${1}/bin/activate
}

servedir() {
    pushd "${1}"
    python3 -m http.server 8080
    popd
}

serve() {
    my_name=$(basename "${1}")
    my_name_enc=$(/usr/bin/env python3 -c "import urllib.parse; print(urllib.parse.quote(\"${my_name}\"))")
    my_mime=$(file -b --mime-type "${1}")
    my_octets=$(stat -f"%z" "${1}")
    cat - <<<"HTTP/1.1 200 OK
Content-Type: ${my_mime}
Content-Length: ${my_octets}
Content-Disposition: attachment; filename=${my_name_enc}
Connection: close
" "${1}" | pv --wait | nc -vl 8080
}

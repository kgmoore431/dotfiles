


get_newusers() {
    newusers="$(gam.py info group newusers | grep member: | cut -d' ' -f3)"
    for i in ${newusers}; do
        gam.py info user $i noaliases nolicenses noschemas | egrep "User:|Last login"
    done
}


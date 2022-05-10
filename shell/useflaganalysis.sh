#!/bin/bash

source /etc/portage/make.conf

known_globals=$(cat /usr/portage/profiles/use.desc  | cut -d ' ' -f 1)

for item in $USE; do
    flag=$(echo $item | sed 's|^-||g')
    if [[ ! $(echo $known_globals | grep -w $flag) ]]; then
        echo "*** $flag is not a global flag: ***"
        cat /usr/portage/profiles/use.local.desc | grep "$flag \- "
        echo ""
    fi
done

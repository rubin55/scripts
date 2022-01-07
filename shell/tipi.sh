#!/usr/bin/env bash

# Key to match.
matchKey="$1"

# user to match.
matchUser="$2"

# Which gpg command to use.
which gpg > /dev/null 2>&1
if [[ $? == 0 ]]; then
    gpg=gpg
else
    gpg=gpg2
fi

# Read gpg files into array.
eval gpgFiles=\($(grep '^[a-z]*=' "$HOME/.tipi.ini" | cut -d = -f 2 | sed -e 's|^|"|g' -e 's|$|"|g' | tr '\n' ' ')\)

for ((i=0; i < ${#gpgFiles[@]}; i++)); do
    $gpg -d ${gpgFiles[$i]} 2> /dev/null | grep -v '^#' | while read -r key user pass; do
        if [[ -z "$matchKey" && -z "$matchUser" ]]; then
            printf "$key\t$user\n" | expand -t 35,63
        elif [[ "$key" =~ "$matchKey" && -z "$matchUser" ]]; then
            printf "$pass" | xclip -in -selection clipboard
            printf "Password for user \"$user\" on \"$key\" placed in copy-paste buffer.\n"
            break
        elif [[ "$key" =~ "$matchKey" && "$user" =~ "$matchUser" ]]; then
            printf "$pass" | xclip -in -selection clipboard
            printf "Password for user \"$user\" on \"$key\" placed in copy-paste buffer.\n"
            break
        fi
    done
done

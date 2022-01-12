#!/usr/bin/env bash

# File format .tipi.ini:
# ; .tipi.ini
# ;
# ; format: key=path
# ; keys are anything you want under the file section.
# ; the value should be a path to a gpg encrypted file.
# ; tsv.gpg format: key <whitespace> <user> <whitespace> <pass>
# ;
# ;
# [files]
# ; <key>=<path>/<file>.tsv.gpg
#
# File format <file>.tsv.gpg
# <key> <whitespace> <user> <whitespace> <pass>
# Lines starting with hash <#> are comment lines

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

# Default echo to display, the password only
clipboard=cat
notify_by_stderr=1

# Check if stdout is a terminal, then check for clipboard tools
if [[ -t 1 ]] ; then
    notify_by_stderr=0
    # if pbcopy found, use command (OS X)
    which pbcopy > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        clipboard="pbcopy -Prefer txt"
    else
        # if xclip found, use command (Generic X)
        which xclip > /dev/null 2>&1
        if [[ $? == 0 ]]; then
            clipboard="xclip -in -selection clipboard"
        fi
    fi
fi

# Read gpg files into array.
eval gpgFiles=\($(grep '^[a-z]*=' "$HOME/.tipi.ini" | cut -d = -f 2 | sed -e 's|^|"|g' -e 's|$|"|g' | tr '\n' ' ')\)

for ((i=0; i < ${#gpgFiles[@]}; i++)); do
    $gpg -d ${gpgFiles[$i]} 2> /dev/null | grep -v '^#' | while read -r key user pass; do
        if [[ -z "$matchKey" && -z "$matchUser" ]]; then
            printf "$key\t$user\n" | expand -t 35,63
        elif [[ "$key" =~ "$matchKey" && -z "$matchUser" ]]; then
            printf "${pass}" | ${clipboard}
            [[ ${notify_by_stderr} -eq 0 ]] && printf "Password for user \"$user\" on \"$key\" placed in copy-paste buffer.\n" 1>&2
            break
        elif [[ "$key" =~ "$matchKey" && "$user" =~ "$matchUser" ]]; then
            printf "${pass}" | ${clipboard}
            [[ ${notify_by_stderr} -eq 0 ]] && printf "Password for user \"$user\" on \"$key\" placed in copy-paste buffer.\n" 1>&2
            break
        fi
    done
done

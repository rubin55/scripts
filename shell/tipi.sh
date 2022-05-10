#!/usr/bin/env bash

# Usage: tipi <key> <user>.
# Note:  the <user> argument is optional.
# Note:  with no <key> or <user> arguments, lists known keys and users.
# Note:  you can also make a link with name <key>-<user>.sh to $baseName.
#
# File format .tipi.ini:
#
#  ; .tipi.ini
#  ;
#  ; format: key=path
#  ; Keys are anything you want under the file section.
#  ; the value should be a path to a tab-separated file.
#  ; tsv format: <key> <whitespace> <user> <whitespace> <pass>
#  ;
#  ;
#  [files]
#  ; <key>=<path>/<file>.tsv
#
# File format <file>.tsv
#
#  <key> <whitespace> <user> <whitespace> <pass>
#
# Lines starting with hash <#> are comment lines.

# Note: when a softlink is created to tipi.sh and the name of the
# script has te structure of "tipi<sep><key><sep><user>.sh" then
# the name wil be expanded to be used as input. For example:
#
#    ln -s tipi.sh tipi_com.google_joedoe.sh
#
# Invokes tipi.sh like:
#
#    tipi.sh com.google joedoe
#

# Print shortcut name error.
function printScriptNameError {
    scriptName="$1"
    echo "Error: name of script \"$scriptName\" has incorrect structure." >&2
    echo "       It should be: \"tipi<sep><key><sep><user>.sh\"" >&2
    echo "       For example:  \"tipi_com.google_johndoe.sh\"" >&2
}

# Get key from script name.
function getKeyFromScriptName {
    scriptName="$1"
    sep="${scriptName:4:1}"
    keyAndUser="${scriptName#*$sep}"
    key="${keyAndUser%%$sep*}"

    if [[ -z "$key" ]] ; then
        printScriptNameError "$scriptName"
        exit 1
    else
        echo "$key"
    fi
}

# Get user from script name.
function getUserFromScriptName {
    scriptName="$1"
    sep="${scriptName:4:1}"
    keyAndUser="${scriptName#*$sep}"
    user="${keyAndUser#*$sep}"

    if [[ -z "$user" ]] ; then
        printScriptNameError "$scriptName"
        exit 1
    else
        echo "$user"
    fi
}

# Set baseName and scriptName.
baseName="$(basename "$0")"
scriptName="${baseName%.sh}"

# Check if we're run directly or through link.
if [[ "$scriptName" == "tipi" ]]; then
    matchKey="$1" # Key to match.
    matchUser="$2" # user to match.
else
    matchKey="$(getKeyFromScriptName "$scriptName")"
    matchUser="$(getUserFromScriptName "$scriptName")"
fi

# Check if ~/.tipi.ini exists.
if [[ ! -r "$HOME/.tipi.ini" ]] ; then
    echo "Error: file \"$HOME/.tipi.ini\" not found or not readable" >&2
    exit 2
fi

# Which gpg command to use?
if which gpg > /dev/null 2>&1; then
    gpg=gpg
else
    echo "Error: \"gpg\" executable not found on path" >&2
    exit 3
fi

# By default, use cat to display the password and use stderr.
clipboard="cat"
useStderr=1

# Check if stdout is a terminal, then check for clipboard tools.
if [[ -t 1 ]] ; then
    useStderr=0

    # Check for xclip on Unix-likes.
    if which xclip > /dev/null 2>&1; then
        clipboard="xclip -in -selection clipboard"
    fi

    # Check for pbcopy on macOS.
    if which pbcopy > /dev/null 2>&1; then
        clipboard="pbcopy -Prefer txt"
    fi

    # Check for clip.exe on Windows/WSL.
    if which clip.exe > /dev/null 2>&1; then
        clipboard="clip.exe"
    fi
fi

# Read gpg files into array.
# shellcheck disable=SC2046
eval gpgFiles=\($(grep '^[a-z]*=' "$HOME/.tipi.ini" | cut -d = -f 2 | sed -e 's|^|"|g' -e 's|$|"|g' | tr '\n' ' ')\)

# Loop over array, find stuff.
# shellcheck disable=SC2154
for ((i=0; i < ${#gpgFiles[@]}; i++)); do
    $gpg -d "${gpgFiles[$i]}" 2> /dev/null | grep -v '^#' | while read -r key user pass; do
        if [[ -z "$matchKey" && -z "$matchUser" ]]; then
            printf '%s\t%s\n' "$key" "$user" #| expand -t 35,63
        elif [[ "$key" =~ $matchKey && -z "$matchUser" ]]; then
            printf '%s' "$pass"  | tr -d "\\n \\r" | ${clipboard}
            [[ ${useStderr} -eq 0 ]] && printf 'Password for user "%s" on "%s" placed in copy-paste buffer.\n' "$user" "$key" 1>&2
            break
        elif [[ "$key" =~ $matchKey && "$user" =~ $matchUser ]]; then
            printf '%s' "$pass" | tr -d "\\n \\r" | ${clipboard}
            [[ ${useStderr} -eq 0 ]] && printf 'Password for user "%s" on "%s" placed in copy-paste buffer.\n' "$user" "$key" 1>&2
            break
        fi
    done
done

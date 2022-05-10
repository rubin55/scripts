#!/bin/bash

# Set default values for certain variables.
color='true'
prefix='$'
verbose='false'

# Terminal escape sequences for text colors.
color_red="\x1b[31m"      #color_red="$(tput setaf 1)"
color_green="\x1b[32m"    #color_green="$(tput setaf 2)"
color_yellow="\x1b[33m"   #color_yellow="$(tput setaf 3)"
color_blue="\x1b[34m"     #color_blue="$(tput setaf 4)"
color_end="\x1b[0m"       #color_end="$(tput sgr0)"

# Platform detection.
platform() {
    local uname="$(uname | tr '[:upper:]' '[:lower:]')"
    local version="$(uname -v | tr '[:upper:]' '[:lower:]')"
    local platform

    if [[ "$uname" =~ "linux" ]]; then
        # Might still be Microsoft's new Windows Services for Linux (wsl).
        if [[ "$version" =~ "microsoft" ]]; then
            platform="windows"
        else
            platform="linux"
        fi
    elif [[ "$uname" =~ "bsd" ]]; then
        platform="bsd"
    elif [[ "$uname" =~ "darwin" ]]; then
        platform="macos"
    elif [[ "$uname" =~ "uwin" || "$uname" =~ "msys" || "$uname" =~ "mingw" || "$uname" =~ "cygwin" ]]; then
        platform="windows"
    else
        platform="unknown"
    fi

    echo "$platform"
}

# Print stuff to stdout.
print() {
    printf "$@\n"
}

# Print stuff to stderr.
error() {
    [[ "$color" = "true" ]] && print "${color_red}$@${color_end}" 1>&2 || print "$@" 1>&2
}

# Print stuff to stderr if verbose mode is enabled.
verbose() {
    if [[ "$verbose" == "true" ]]; then
        [[ "$color" = "true" ]] && print "${color_yellow}$@${color_end}" 1>&2 || print "$@" 1>&2
    fi
}

# Get words starting with $prefix within a string.
getkeys() {
    local string=$1
    grep -o "${prefix}\w*" <<< "$string"
}

# Get the character position of a word within a string.
strindex() {
    local string=$1
    local word=$2
    local x="${string%%$word*}"
    [[ "$x" = "$string" ]] && echo -1 || echo $((${#x}+1))
}

# Get a value from the key store, make sure $prefix is filtered out.
getval() {
    local cmd=""
    local req=${1/$prefix/}

    if [[ "$tsvfile" =~ \.gpg$ ]]; then
        # The store is a gpg file. We're using gpg.
        cmd="gpg -d "

        # If pass was passed, use it.
        if [[ ! -z "$secret" ]]; then
            cmd="$cmd --passphrase $secret --pinentry-mode loopback "
        fi
    else
        # The store is not a gpg file. We're using cat.
        cmd="cat "
    fi

    # If TSV file was passed, search it and replace what's found.
    if [[ -f "$tsvfile" ]]; then
        $cmd "$tsvfile" 2> /dev/null | grep -v '^#' | while read -r key type value; do
            if [[ "$key" == "$req" ]]; then
                decode "$type" "$value"
            fi
        done
    fi

    # If envsub mode is enabled, do like envsubst would do.
    if [[ "$envsub" == "true" ]]; then
        env | sed 's/=/\'$'\tstring\t/1' | while read -r key type value; do
            if [[ "$key" == "$req" ]]; then
                decode "$type" "$value"
            fi
        done
    fi
}

# Decode values based on type.
decode() {
    local cmd=""
    local type=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    local string=$2

    case "$type" in
        "base64")
        cmd="base64 -d "
        ;;
        "string")
        cmd="cat "
        ;;
        *)
        error "Error: unknown type: \"$type\" specified"
        cmd="echo"
        return 1
        ;;
    esac

    $cmd <<< "$string"
}

# A simple help message.
usage() {
    print "Usage: $(basename "$0") (-e) -t <tsv_file> -k <key_file> -s <secret> -p <prefix_string> file_to_parse (or stdin)"
    print ""
    print "    -e            Enable envsub(st) mode. Will replace any environment"
    print "                  variables encountered with set values."
    print "                  Works more or less like envsubst."
    print "    -t tsvfile    Tab-separated key/value store, can be encrypted"
    print "                  using GnuPG. Defaults to \"~/.store.tsv.gpg\"."
    print "    -k keyfile    Optional. Specifies private key to be used. Will"
    print "                  be imported into current user's GnuPG keychain."
    print "    -s secret     Optional. Specifies a passphrase for the private"
    print "                  key used to encrypt the keystore."
    print "    -p prefix     Optional. Prefix for keys in the file to parse. "
    print "                  Defaults to \"\$\"."
    print "    -v            Enable verbose logging to stderr."
    print "    -c            Toggle color output mode. Enabled by default."
    print "    -h            Display help."
    print ""
    print "$(basename "$0") can use an (optionally encrypted with GnuPG) tab-separated"
    print "key/value store (which is a regular TSV file with three columns:"
    print "KEY, TYPE and VALUE, where TYPE can be \"base64\" or \"string\")."
    print ""
    print "The file_to_parse will contain keys which are prefixed with some"
    print "set of characters (which is \"\$\" by default). For example, having:"
    print ""
    print "    FOO<tab>string<tab>bar"
    print ""
    print "in the key/value store and \$FOO in the file_to_parse, will then"
    print "result in the replacement of \"\$FOO\" with \"bar\"."
    print ""
    print "Note that if the type is \"base64\" instead of \"string\", the value"
    print "will first be decoded using the base64 utility."
    print ""
    print "Also note that you can use the \"-e\" option to replace environment"
    print "variables, just like envsubst would do. Can be used in combination"
    print "with \"-t\". When using the \"-e\" option, all values retrieved from"
    print "the environment are assumed to be of type \"string\"."
    print ""
    exit 1
}

# Do some getopt magic.
while getopts "t:k:s:p:evch" arg; do
    case $arg in
        c)
            color="false"
            ;;
        e)
            envsub="true"
            ;;
        t)
            tsvfile="$OPTARG"
            ;;
        k)
            keyfile="$OPTARG"
            ;;
        s)
            secret="$OPTARG"
            ;;
        p)
            prefix="$OPTARG"
            ;;
        v)
            verbose="true"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# Check if tsvfile was passed and exists.
if [[ ! -z "$tsvfile" && ! -f "$tsvfile" ]]; then
    error "Error: TSV file: \"$tsvfile\" was passed but file does not exist."
    exit 1
fi

# Check if keyfile was passed and exists, try to import it.
if [[ ! -z "$keyfile" && -f "$keyfile" ]]; then
    verbose "Key file specified and exists. Attempting to (re)import key: $keyfile"
    gpg --batch --import "$keyfile" 2> /dev/null
fi

# Main iterator, echo each line, if keys are found on a line,
# look them up and replace the key with the value.
count=0
while IFS= read -r line; do
    ((++count))
    for key in $(getkeys "$line"); do
        value=$(getval "$key")
        column=$(strindex "$line" "$key")
        indent=$((column-1))
        if [[ ! -z "$value" ]]; then
            line="$(python -c "from __future__ import print_function;import re,sys; print(sys.stdin.read().replace(sys.argv[1], re.sub(r'\n', '\n' + (int(sys.argv[3]) * ' '), sys.argv[2])))" "$key" "$value" "$indent" <<< "$line")"
        fi
        verbose "     key: '$key'"
        verbose "   value: '$(python -c "print('*' * ${#value})")'"
        verbose "position: '$count,$column'"
        verbose "  indent: '$indent'"
    done
    echo "$line"
done < "${1:-/dev/stdin}"

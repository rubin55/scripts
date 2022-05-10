#!/bin/bash

# Source ~/.getcolor.conf if it exists. You can use it to specify a default
# Xresources file for example to look for if it's not passed explicitly as $2.
config="$HOME/.getcolor.conf"
if [ -e "$config" ]; then
    source "$config"
fi

# Report functions.
function report { printf "$*\n" ; }
function reportApp { report "getcolor: $*" ; }
function reportInfo { reportApp "Info: $*" ; }
function reportWarning { reportApp "Warning: $*" >&2 ; }
function reportError { reportApp "Error: ${FUNCNAME[1]}(): $*" >&2 ; }
function reportDebug {
    [ ! "$debug" -o  "$debug" = 0 ] && return
    typeset msg
    msg="Debug: ${FUNCNAME[1]}(): $*"
    reportApp "$msg" >&2
}

# Check for neccessary required executables.
reqs="cpp cut grep printf sed"
chkd=""
for req in $reqs; do
    which "$req" > /dev/null 2>&1
    if [ $? -gt 0 ]; then
       chkd="$req $chkd"
    fi
done
chkd=$(echo $chkd | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [ "$chkd" ]; then
    reportError "A few required executables were not found on the path:"
    reportError "$chkd"
    exit 1
fi

# Parameter two: optional name of the Xresources file. Can also be set in the
# configuration file sourced earlier (specified there as xresources=foo).
file="$2"

# The Xresources file we work with. Note that we don't use xrdb since that would
# force the user of $0 to have a running X server. We parse Xresources ourselves
# thus making it possible to use $0 in pure terminal/console only environments.
if [ -z "$xresources" -a -z "$file" ]; then
    # Not set in $config or passed as file, set to defaults.
    xresources="$HOME/.Xresources"
elif [ "$file" ]; then
    # Specified as argument, override whatever is set in $config.
    xresources="$file"
fi

# Check for xresources file existence.
if [ ! -e "$xresources" ]; then
    reportError "No Xresources file found. I was looking for:"
    reportError "$xresources"
    exit 1
fi

# The standard X11 color names. If we don't find this file we trigger a warning
# because it means we can't find colors specified by name instead of hex.
if [ -z "$xcolors" ]; then
    # Not set in $config, set to defaults.
    xcolors=/usr/share/X11/rgb.txt
fi

# Check for xcolors file existence.
if [ ! -e "$xcolors" ]; then
    reportWarning "No xcolors file found. That means I will treat colors specified"
    reportWarning "by name as Xresources defines to follow. I was looking for:"
    reportWarning "$xcolors"
fi

# Who knew? Xresources files are cpp processable. Create a processed xresources
# that automatically handles defines and includes, remove comments.
data="$(cpp "$xresources" | grep -ve '^!' -ve '^#')"

# Parameter one: name of key containing (define pointing to) color.
key="$1"
if [ -z "$key" ]; then
    reportError "No key specified. please specify an Xresources key pointing to a color."
    reportError "For example: $0 color7"
    reportError ""
    reportError "Listing currently known colors:"
    echo "$data" | grep -e color -e ground
    exit 1
fi

#TODO: implement follow defines until color data returned
#TODO: find keys that specify a color by hex
#TODO: find keys that specify colot by name
#TODO: implement arbitrary xresources key specification

function getColor() {
    typeset key=$1
    reportDebug "Key \"$key\" returns the following candidates:\n $(echo "$data" | grep -w "$key")"
    color=$(echo "$data" | grep -w "$key" | cut -d: -f 2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ "$color" ]; then
        if [[ ! "$color" =~ "#" ]]; then
            reportInfo "Color specified by name: \"$color\". Converting to hex"
            colorName="$color"
            colorLine="$(grep -wi "$color" "$xcolors")"
            if [ "$colorLine" ]; then
                color=$(printf "#%02x%02x%02x\n" $(echo "$colorLine" | cut -f 1))
            else
                reportError "Unable to find color $color in $xcolors."
                return 1
            fi
        fi
    else
        reportError "Unable to find key $key in $xresources."
        return 1
    fi

    echo "$color"
}

getColor "$key"

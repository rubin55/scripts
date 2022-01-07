#!/usr/bin/env bash


# Prints the standard help message for this utility.
function printUsageText {
    printf "%s\n" "\
    Usage: $0 command

    Commands:
    on          - (tries to) enable multi-display using XRandR.
    off         - (tries to) disable multi-display using XRandR.
    version     - Display the version of this application.
    help        - Display this usage and help message.
   
    " | sed 's/^[[:space:]]*//'
}

# Prints the version of session.
function printVersion {
    echo "MultiDisplay version 1.0.0.1017 trunk
    Copyright © 2008-2015 RAAF Technology bv
    Released March 04 2015 12:02 UTC
    Built March 04 2015 12:00 UTC
    Licensed under GPLv3
" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Main case statement.
case $1 in 
    on)
    connectedCount=$(xrandr -q | grep -w connected | wc -l)
    if [ $connectedCount -gt 1 ]; then
        xrandr --output LVDS1 --auto --left-of DP2 --output DP2 --auto --output DP3 --auto --right-of DP2
    else
        echo "Not changing display setup because only found $connectedCount connected displays."
    fi
    ;;
    off)
    connectedCount=$(xrandr -q | grep -w connected | wc -l)
    if [ $connectedCount -gt 1 ]; then
        xrandr --output DP3 --off --output DP2 --off
    else
        echo "Not changing display setup because only found $connectedCount connected displays."
    fi
    ;;
    version)
    printVersion
    ;;
    help|--help|-h)
    printUsageText
    exit 0
    ;;
    *)
    printUsageText
    exit 1
    ;;
esac

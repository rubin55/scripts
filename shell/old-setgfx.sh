#!/usr/bin/env bash


# Prints the standard help message for this utility.
function printUsageText {
    printf "%s\n" "\
    Usage: $0 command

    Commands:
    intel       - Set xorg.conf to intel variant.
    nvidia      - Set xorg.conf to nvidia variant.
    version     - Display the version of this application.
    help        - Display this usage and help message.
   
    " | sed 's/^[[:space:]]*//'
}

# Prints the version of session.
function printVersion {
    echo "SetGfx version 1.0.0.1017 trunk
    Copyright © 2008-2015 RAAF Technology bv
    Released September 24 2015 15:02 UTC
    Built September 24 2015 15:00 UTC
    Licensed under GPLv3
" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Main case statement.
case $1 in 
    intel)
    if [ -e "/etc/X11/xorg.conf.intel" ]; then
        sudo rm /etc/X11/xorg.conf
        sudo ln -s /etc/X11/xorg.conf.intel /etc/X11/xorg.conf
        echo "Enabled intel configuration. You can now run X."
    else
        echo "No configuration for intel found."
        exit 1
    fi
    ;;
    nvidia)
    if [ -e "/etc/X11/xorg.conf.nvidia" ]; then
        sudo rm /etc/X11/xorg.conf
        sudo ln -s /etc/X11/xorg.conf.nvidia /etc/X11/xorg.conf
        echo "Enabled nvidia configuration. You can now run X."
    else
        echo "No configuration for nvidia found."
        exit 1
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

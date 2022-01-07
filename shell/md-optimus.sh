#!/usr/bin/env bash

bumblebeeConf='/etc/bumblebee/bumblebee.conf'
bumblebeeXorgNvidia='/etc/bumblebee/xorg.conf.nvidia'

# Global settings.
keepUnusedXorgServerEnabled='KeepUnusedXServer=true'
keepUnusedXorgServerDisabled='KeepUnusedXServer=false'
optimusVirtualMonitorEnabled='Option "ConnectedMonitor" "DFP"'
optimusVirtualMonitorDisabled='#Option "ConnectedMonitor" "DFP"'


# Prints with standard framing text.
function report { printf "$*\n" ; }
function reportInfo { report "[INFO]: $*" ; }
function reportWarning { report "[WARN]: $*" >&2 ; }
function reportError { report "[ERROR]: ${FUNCNAME[1]}(): $*" >&2 ; }
function reportDebug {
    [ ! "$debug" -o  "$debug" = 0 ] && return
    typeset msg
    msg="[DEBUG]: ${FUNCNAME[1]}(): $*"
    report "$msg" >&2
    [ ! "$logfile" ] || printf "%s\n" "$msg" >> "$logfile"
}

# Check if we have root permissions.
function permissionCheck {
	if [ "$(id -u)" != "0" ]; then
        reportError "This function must be run as root."
        exit 1
    fi
}

# Check if connected monitor is enabled in xorg.conf.nvidia.
function optimusVirtualMonitorCheck {
	typeset check="unknown"
	
	if [ "$(grep "$optimusVirtualMonitorDisabled" "$bumblebeeXorgNvidia")" ]; then
	    check="disabled"
		echo $check
		return 0
	elif [ "$(grep "$optimusVirtualMonitorEnabled" "$bumblebeeXorgNvidia")" ]; then
	    check="enabled"
		echo $check
		return 0
	else
		reportError "Could not determine connected monitor state."
		echo $check
		return 1
	fi
}

# Set connected monitor string to enabled (which is required for optirun on laptop lcd).
function optimusVirtualMonitorEnable {
	typeset check=$(optimusVirtualMonitorCheck)

	if [ $check == disabled ]; then
		reportInfo "Enabling connected monitor string in $bumblebeeXorgNvidia.."
		sed -i "s|$optimusVirtualMonitorDisabled|$optimusVirtualMonitorEnabled|g" "$bumblebeeXorgNvidia"
		return 0
	fi
}

# Set connected monitor string to disabled (which is required when connecting multiple displays).
function optimusVirtualMonitorDisable {
	typeset check=$(optimusVirtualMonitorCheck)

	if [ $check == enabled ]; then
		reportInfo "Disabling connected monitor string in $bumblebeeXorgNvidia.."
		sed -i "s|$optimusVirtualMonitorEnabled|$optimusVirtualMonitorDisabled|g" "$bumblebeeXorgNvidia"
		return 0
	fi
}

# Check if keep unused X11 server is enabled in bumblebee.conf.
function keepUnusedXorgServerCheck {
	typeset check="unknown"
	
	if [ "$(grep "$keepUnusedXorgServerDisabled" "$bumblebeeConf")" ]; then
	    check="disabled"
		echo $check
		return 0
	elif [ "$(grep "$keepUnusedXorgServerEnabled" "$bumblebeeConf")" ]; then
	    check="enabled"
		echo $check
		return 0
	else
		reportError "Could not determine the setting related to keeping an unused Xorg server running."
		echo $check
		return 1
	fi
}

# Set feature to keep unused Xorg server running to true (which is required when connecting multiple displays).
function keepUnusedXorgServerEnable {
	typeset check=$(keepUnusedXorgServerCheck)

	if [ $check == disabled ]; then
		reportInfo "Enabling feature to keep unused Xorg server in $bumblebeeXorgNvidia.."
		sed -i "s|$keepUnusedXorgServerDisabled|$keepUnusedXorgServerEnabled|g" "$bumblebeeConf"
		return 0
	fi
}

# Set feature to keep unused Xorg server running to false (which is required for optirun on laptop lcd).
function keepUnusedXorgServerDisable {
	typeset check=$(keepUnusedXorgServerCheck)

	if [ $check == enabled ]; then
		reportInfo "Disabling feature to keep unused Xorg server in $bumblebeeXorgNvidia.."
		sed -i "s|$keepUnusedXorgServerEnabled|$keepUnusedXorgServerDisabled|g" "$bumblebeeConf"
		return 0
	fi
}

# Check if multiple display support is enabled or not.
function multipleDisplaySupportCheck {
	typeset checkVirtualMonitorSetting=$(optimusVirtualMonitorCheck)
    typeset checkKeepUnusedXorgSetting=$(keepUnusedXorgServerCheck)
    
    if [ $checkVirtualMonitorSetting = enabled -a $checkKeepUnusedXorgSetting = disabled ]; then 
    	multipleDisplaySupport=disabled; 
    elif [ $checkVirtualMonitorSetting = disabled -a $checkKeepUnusedXorgSetting = enabled ]; then
    	multipleDisplaySupport=enabled;
    else
    	reportError "Strangeness encountered."
    	multipleDisplaySupport=unknown
    fi

	reportInfo "Optimus multiple monitor support: $multipleDisplaySupport"
}


# Prints the standard help message for this utility.
function printUsageText {
    printf "%s\n" "\
    Usage: $0 command

    Commands:
    enable      - (tries to) enable multi-display with NVIDIA Optimus support.
    disable     - (tries to) disable multi-display with NVIDIA Optimus support.
    status      - Checks the status of multiple display setup.
    version     - Display the version of this application.
    help        - Display this usage and help message.
   
    Notes:
    You need to disable when you want to use optirun/primusrun on the primary 
    LCD and/or single display, ie. when no external monitors are connected.

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
    enable)
    permissionCheck
    optimusVirtualMonitorDisable
    keepUnusedXorgServerEnable
    multipleDisplaySupportCheck
    kill -HUP $(pidof bumblebeed)
    ;;
    disable)
    permissionCheck
    optimusVirtualMonitorEnable
    keepUnusedXorgServerDisable
    multipleDisplaySupportCheck
    kill -HUP $(pidof bumblebeed)
    ;;
    status)
    multipleDisplaySupportCheck
    exit 0
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

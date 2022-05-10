#!/usr/bin/env bash

# Global variables.
localUser="db2"
localGroup="db2"
localHome="/opt/db2/home"

# Check if we are root.
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Prints the standard help message for this utility.
function printUsageText {
    printf "%s\n" "\
    Usage: $0 command

    Commands:
    status       - Show the status of the local DB2 instance.
    start        - Start the local DB2 instance.
    stop         - Stop the local DB2 instance.
    log          - Tail the DB2 diagnostics log.
    version      - Shows the version of the application.
    help         - Display this usage and help message.
   
    " | sed 's/^[[:space:]]*//'
}

# Prints the version of session.
function printVersion {
    echo "DB2 Tool version 1.0.0.1023 trunk
    Copyright © 2008-2015 RAAF Technology bv
    Released October 29 2015 11:51 UTC
    Built October 29 2015 11:52 UTC
    Licensed under GPLv3
" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Prints the running status.
function printStatus {
    status=unknown
    if [ -z "$(ps ax | grep db2sysc | grep -v grep)" ]; then
        status=stopped
    else
        status=started
    fi
    echo $status
}

# Main case statement.
case $1 in 
    status)
    printStatus
    ;;
    start)
    if [ $(printStatus) == stopped ]; then
        su -l db2 -c /opt/db2/sqllib/adm/db2start
    else
        echo "Server is already running."
        exit 1
    fi
    ;;
    stop)
    if [ $(printStatus) == started ]; then
        su -l db2 -c /opt/db2/sqllib/adm/db2stop
    else
        echo "Server is already stopped."
        exit 1
    fi
    ;;
    log)
    su -l db2 -c /opt/db2/sqllib/bin/db2diag -f
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

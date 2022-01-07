#!/usr/bin/env bash

# Global variables.
localUser="oracle"
localGroup="oracle"
localHome="/opt/oracle/home"

# Check if we are root.
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

if [ -e "/etc/profile.d/opt-oracle.sh" ]; then
    . /etc/profile.d/opt-oracle.sh
fi

# Prints the standard help message for this utility.
function printUsageText {
    printf "%s\n" "\
    Usage: $0 command

    Commands:
    status       - Show the status of the local Oracle instance.
    start        - Start the local Oracle instance.
    stop         - Stop the local Oracle instance.
    log          - Tail the Oracle diagnostics log.
    version      - Shows the version of the application.
    help         - Display this usage and help message.

    " | sed 's/^[[:space:]]*//'
}

# Prints the version of session.
function printVersion {
    echo "Oracle Tool version 1.0.0.1236 trunk
    Copyright © 2008-2017 RAAF Technology bv
    Released April 11 2017 08:29 UTC
    Built April 11 2017 08:28 UTC
    Licensed under GPLv3
" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Prints the running status.
function printStatus {
    status=unknown
    if [ -z "$(ps ax | grep pmon | grep -v grep)" ]; then
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
       su -l $localUser -c "$ORACLE_HOME/bin/dbstart $ORACLE_HOME"
    else
        echo "Server is already running."
        exit 1
    fi
    ;;
    stop)
    if [ $(printStatus) == started ]; then
        su -l $localUser -c "$ORACLE_HOME/bin/dbshut $ORACLE_HOME"
    else
        echo "Server is already stopped."
        exit 1
    fi
    ;;
    log)
    tail -f $ORACLE_HOME/*.log
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

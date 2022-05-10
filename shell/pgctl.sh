#!/usr/bin/env bash

# Global variables.
platform=$(uname -s | tr '[:upper:]' '[:lower:]')

# But if it's WSL..
if [[ "$(uname -r)" =~ "Microsoft" ]]; then
        platform=windows
fi

case "$platform" in
    darwin)
	pgData="$HOME/Library/Application Support/Postgres/var-12"
    ;;
    bsd|gnu/linux|linux|unix|windows)
	pgData="$HOME/.postgres/data"
    ;;
    *)
    echo "Unknown platform \"$platform\"."
    exit 1
esac

# Prints the standard help message for this utility.
function printUsageText {
    printf "%s\n" "\
    Usage: $0 command

    Commands:
    status       - Show the status of the local PostgreSQL instance.
    start        - Start the local PostgreSQL instance.
    stop         - Stop the local PostgreSQL instance.
    version      - Shows the version of the application.
    help         - Display this usage and help message.

    " | sed 's/^[[:space:]]*//'
}

# Prints the version of session.
function printVersion {
    echo "pgctl version 1.0.1 trunk
    Copyright © 2008-2020 RAAF Technology bv
    Released August 13 2020 19:43 UTC
    Built October 13 2020 19:42 UTC
    Licensed under GPLv3
" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Prints the running status.
function printStatus {
    status=unknown
    if [ "$(pg_ctl -D "$pgData" status | grep 'no server running')" ]; then
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
        pg_ctl -D "$pgData" start
    else
        echo "Server is already running."
        exit 1
    fi
    ;;
    stop)
    if [ $(printStatus) == started ]; then
        pg_ctl -D "$pgData" stop
    else
        echo "Server is already stopped."
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

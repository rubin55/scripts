#!/usr/bin/env bash

# You can create an artemis instance with the following command:
#
# artemis create --aio --host THINK --no-hornetq-acceptor --no-mqtt-acceptor --no-stomp-acceptor --require-login --user admin artemis

# Global variables.
platform=$(uname -s | tr '[:upper:]' '[:lower:]')

# But if it's WSL..
if [[ "$(uname -r)" =~ "Microsoft" ]]; then
        platform=windows
fi

case "$platform" in
    darwin)
	ARTEMIS_DATA="$HOME/Library/Application Support/Artemis/data"
    ;;
    bsd|gnu/linux|linux|unix|windows)
	ARTEMIS_DATA="$HOME/.activemq/artemis/data"
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
    status       - Show the status of the local Artemis instance.
    start        - Start the local Artemis instance.
    stop         - Stop the local Artemis instance.
    version      - Shows the version of the application.
    help         - Display this usage and help message.

    " | sed 's/^[[:space:]]*//'
}

# Prints the version of session.
function printVersion {
    echo "amqctl version 1.0.0 trunk
    Copyright © 2022 RAAF Technology bv
    Released December 16 2022 23:08 UTC
    Built December 16 2022 23:08 UTC
    Licensed under GPLv3
" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Prints the running status.
function printStatus {
    status=unknown
    if [ "$("$ARTEMIS_DATA/../bin/artemis-service" status | grep 'artemis-service is stopped')" ]; then
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
        "$ARTEMIS_DATA/../bin/artemis-service" start
    else
        echo "Server is already running."
        exit 1
    fi
    ;;
    stop)
    if [ $(printStatus) == started ]; then
        "$ARTEMIS_DATA/../bin/artemis-service" stop
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

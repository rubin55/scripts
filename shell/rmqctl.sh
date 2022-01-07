#!/usr/bin/env bash

# Global variables.
platform=$(uname -s | tr '[:upper:]' '[:lower:]')

# But if it's WSL..
if [[ "$(uname -r)" =~ "Microsoft" ]]; then
        platform=windows
fi

case "$platform" in
    darwin)
        RABBITMQ_MNESIA_BASE="$HOME/Library/Application Support/RabbitMQ/mnesia"
        RABBITMQ_LOG_BASE="$HOME/Library/Application Support/RabbitMQ/logs"
    ;;
    bsd|gnu/linux|linux|unix|windows)
        RABBITMQ_MNESIA_BASE="$HOME/.rabbitmq/mnesia"
        RABBITMQ_LOG_BASE="$HOME/.rabbitmq/logs"
    ;;
    *)
    echo "Unknown platform \"$platform\"."
    exit 1
esac

export RABBITMQ_MNESIA_BASE RABBITMQ_LOG_BASE

# Prints the standard help message for this utility.
function printUsageText {
    printf "%s\n" "\
    Usage: $0 command

    Commands:
    status       - Show the status of the local RabbitMQ instance.
    start        - Start the local RabbitMQ instance.
    stop         - Stop the local RabbitMQ instance.
    version      - Shows the version of the application.
    help         - Display this usage and help message.

    " | sed 's/^[[:space:]]*//'
}

# Prints the version of session.
function printVersion {
    echo "rmqctl version 1.0.0 trunk
    Copyright © 2020 RAAF Technology bv
    Released August 13 2020 19:19 UTC
    Built August 13 2020 19:18 UTC
    Licensed under GPLv3
" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Prints the running status.
function printStatus {
    status=unknown
    rabbitmqctl status > /dev/null 2>&1
    if [ $? == 0 ]; then
        status=started
    else
        status=stopped
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
        rabbitmq-server -detached
    else
        echo "Server is already running."
        exit 1
    fi
    ;;
    stop)
    if [ $(printStatus) == started ]; then
        rabbitmqctl stop
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

#!/usr/bin/env bash

# Global variables.
hostname=$(hostname | cut -d '.' -f 1 | tr 'A-Z' 'a-z')
platform=$(uname -s | tr '[:upper:]' '[:lower:]')
mqserver=/usr/lib/rabbitmq/bin/rabbitmq-server
mqctl=/usr/lib/rabbitmq/bin/rabbitmqctl

# But if it's WSL..
if [[ "$(uname -r)" =~ "Microsoft" ]]; then
        platform=windows
fi

export RABBITMQ_NODENAME=rabbit@$hostname
export RABBITMQ_NODE_IP_ADDRESS=127.0.0.1
export RABBITMQ_NODE_PORT=5672

case "$platform" in
    darwin)
        export RABBITMQ_CONFIG_FILE="$HOME/Library/Application Support/RabbitMQ/rabbitmq.conf"
        export RABBITMQ_CONF_ENV_FILE="$HOME/Library/Application Support/RabbitMQ/rabbitmq-env.conf"
        export RABBITMQ_ENABLED_PLUGINS_FILE="$HOME/Library/Application Support/RabbitMQ/enabled_plugins"
        export RABBITMQ_MNESIA_BASE="$HOME/Library/Application Support/RabbitMQ/mnesia"
        export RABBITMQ_LOG_BASE="$HOME/Library/Application Support/RabbitMQ/logs"
    ;;
    bsd|gnu/linux|linux|unix|windows)
        export RABBITMQ_CONFIG_FILE="$HOME/.rabbitmq/rabbitmq.conf"
        export RABBITMQ_CONF_ENV_FILE="$HOME/.rabbitmq/rabbitmq-env.conf"
        export RABBITMQ_ENABLED_PLUGINS_FILE="$HOME/.rabbitmq/enabled_plugins"
        export RABBITMQ_MNESIA_BASE="$HOME/.rabbitmq/mnesia"
        export RABBITMQ_LOG_BASE="$HOME/.rabbitmq/logs"
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
    status       - Show the status of the local RabbitMQ instance.
    start        - Start the local RabbitMQ instance.
    stop         - Stop the local RabbitMQ instance.
    env          - A source-able environment.
    version      - Shows the version of the application.
    help         - Display this usage and help message.

    Notes:
    You can enable the management API with 
    rabbitmq-plugins enable rabbitmq_management
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
    $mqctl status > /dev/null 2>&1
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
        $mqserver -detached
    else
        echo "Server is already running."
        exit 1
    fi
    ;;
    stop)
    if [ $(printStatus) == started ]; then
        $mqctl stop
    else
        echo "Server is already stopped."
        exit 1
    fi
    ;;
    env)
    env | grep RABBITMQ | sed 's|^RABBITMQ_|export RABBITMQ_|'
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

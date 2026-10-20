#!/usr/bin/env bash

# Global variables. Neo4j keeps data in $NEO4J_HOME/data.
export NEO4J_HOME="$HOME/.neo4j"

# Prints the standard help message for this utility.
function printUsageText {
    printf "%s\n" "\
    Usage: $0 command

    Commands:
    status       - Show the status of the local Neo4j instance.
    start        - Start the local Neo4j instance.
    stop         - Stop the local Neo4j instance.
    version      - Shows the version of the application.
    help         - Display this usage and help message.

    " | sed 's/^[[:space:]]*//'
}

# Prints the version of session.
function printVersion {
    echo "n4ctl version 1.0.0 trunk
    Copyright © 2026 RAAF Technology bv
    Released October 20 2026 21:44 UTC
    Built October 20 2026 21:44 UTC
    Licensed under GPLv3
" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Prints the running status.
function printStatus {
    if neo4j status > /dev/null 2>&1; then
        echo started
    else
        echo stopped
    fi
}

# Main case statement.
case $1 in
    status)
    printStatus
    ;;
    start)
    if [ "$(printStatus)" == stopped ]; then
        mkdir -p "$NEO4J_HOME"
        neo4j start
    else
        echo "Server is already running."
        exit 1
    fi
    ;;
    stop)
    if [ "$(printStatus)" == started ]; then
        neo4j stop
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

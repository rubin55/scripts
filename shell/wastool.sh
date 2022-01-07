#!/usr/bin/env bash

# Check if we are root.
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Aliases.
alias session='/home/rubin/Source/Projects/Eclipse/session/target/ant-build/session.sh'

# Global variables.
localWasJre="/opt/was/appserver/java/bin/java"
localProfile="/opt/was/data/regular/wasdev01"
localAddr="127.0.0.1"
localHost="tezro"
localServer="server01"
localUser="rubin"
localGroup="users"
localBuildDir="/home/rubin/IBM/Source/Projects/Eclipse"

remoteAddr="172.17.1.48"
remoteHost="donald"
remoteUser="was"
remoteBuildDir="/data/was/build"

# Prints the standard help message for this utility.
function printUsageText {
    printf "%s\n" "\
    Usage: $0 command

    Commands:
    status       - Show the status of the local WAS instance.
    start        - Start the local WAS instance.
    stop         - Stop the local WAS instance.
    log <app>    - Tail SystemLog or app-specific logs.
    clean        - Clean all log and temporary files of the 
                   local WAS instance. 
    deploy <app> - Deploy an EAR application to a remote 
                   WAS instance.
    version      - Shows the version of the application.
    help         - Display this usage and help message.
   
    " | sed 's/^[[:space:]]*//'
}

# Prints the version of session.
function printVersion {
    echo "WAS Tool version 1.0.0.1023 trunk
    Copyright © 2008-2015 RAAF Technology bv
    Released October 29 2015 11:51 UTC
    Built October 29 2015 11:52 UTC
    Licensed under GPLv3
" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Prints the running status.
function printStatus {
    status=unknown
    if [ -z "$(ps ax | grep "$localWasJre" | grep -v grep)" ]; then
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
        su -l "$localUser" -c "$localProfile/bin/startServer.sh $localServer"
    else
        echo "Server is already running."
        exit 1
    fi
    ;;
    stop)
    if [ $(printStatus) == started ]; then
        su -l "$localUser" -c "$localProfile/bin/stopServer.sh $localServer -username admin -password WASMASTER"
    else
        echo "Server is already stopped."
        exit 1
    fi
    ;;
    log)
    logNames="was dcas pcas saad blueauditor"
    logTypes="main error debug"

    app="$2"
    type="$3"
    case $app in
        was)
        case $type in
            main)
            tail -f $localProfile/logs/$localServer/SystemOut.log
            ;;
            error)
            tail -f $localProfile/logs/$localServer/SystemErr.log
            ;;
            debug)
            echo "No debug log available for was."
        esac
        ;;
        dcas)
        case $type in
            main)
            tail -f $localProfile/logs/${app}.log
            ;;
            error)
            tail -f $localProfile/logs/${app}-error.log
            ;;
            debug)
            tail -f $localProfile/logs/${app}-debug.log
        esac
        ;;
        pcas)
        case $type in
            main)
            tail -f $localProfile/logs/${app}.log
            ;;
            error)
            tail -f $localProfile/logs/${app}-error.log
            ;;
            debug)
            tail -f $localProfile/logs/${app}-debug.log
        esac
        ;;
        saad)
        case $type in
            main)
            tail -f $localProfile/logs/${app}.log
            ;;
            error)
            tail -f $localProfile/logs/${app}-error.log
            ;;
            debug)
            tail -f $localProfile/logs/${app}-debug.log
        esac
        ;;
        blueauditor)
        case $type in
            main)
            tail -f $localProfile/logs/${app}.log
            ;;
            error)
            tail -f $localProfile/logs/${app}-error.log
            ;;
            debug)
            tail -f $localProfile/logs/${app}-debug.log
        esac
        ;;
        *)
        echo "Please specify a log to follow:"
        echo "  $logNames"
        echo ""
        echo "and a respective log type:"
        echo "  $logTypes"
        echo ""
        echo "For example:"
        echo " wastool log dcas debug"
    esac
    ;;
    clean)
    if [ $(printStatus) == stopped ]; then
        rm -rf $localProfile/wstemp
        mkdir -p $localProfile/wstemp

        rm -rf $localProfile/workspace
        mkdir -p $localProfile/workspace

        rm -rf $localProfile/temp
        mkdir -p $localProfile/temp

        rm -f $localProfile/logs/*.log
        rm -f $localProfile/logs/server1/*.*
        rm -f $localProfile/logs/ffdc/*.*
        rm -f $localProfile/logs/wsadmin*

	rm -rf $localProfile/databases/EJBTimers/server01/EJBTimerDB

        chown -R $localUser:$localGroup $localProfile
    else
        echo "Server is running. Cowardly refusing to clean."
        exit 1
    fi

    ;;
    deploy)

    app="$2"
    if [ ! -e "$localBuildDir/$app/pom.xml" ]; then
        echo "Please specify a valid maven app."
        echo "I'm looking in: $localBuildDir"
        exit 1
    fi

    . ~/.session/tmp/session.ssh-agent.out

    echo "[INFO] Sending $app to $remoteHost:$remoteBuildDir/$app"
    rsync -avzPHSc --delete --quiet $localBuildDir/$app/ $remoteUser@$remoteAddr:$remoteBuildDir/$app/

    echo "[INFO] Invoking packaging build on $remoteHost:$remoteBuildDir/$app"
    session tell $remoteHost --command="'mvn -f $remoteBuildDir/$app/pom.xml package'"

    echo "[INFO] Deploying $app on WebSphere Application Server running on $remoteHost" 
    session tell $remoteHost --command="'/apps/was/as/traditional/bin/wsadmin.sh -user admin -password WASMASTER -lang jython -f /data/was/deploy/$app.py'"
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

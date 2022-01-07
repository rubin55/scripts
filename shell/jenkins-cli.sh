#!/usr/bin/env bash

# Determine where $JENKINS_HOME is.
if [ ! $JENKINS_HOME ]; then
    ABS="$PWD"
    IFS="/"
    for DIR in $0; do
        if [ -n "$DIR" ]; then
            if [ "$DIR" = ".." ]; then
                ABS="${ABS%/*}"
            elif [ "$DIR" != "." ]; then
                ABS="$ABS/$DIR"
            fi;
        fi;
    done;
    unset DIR
    unset IFS
    OFFSET="/../"
    if [ -e "`dirname "$ABS"`$OFFSET" ]; then
        # Found, probably called relatively.
        cd "`dirname "$ABS"`$OFFSET"
        JENKINS_HOME="`pwd`"
        unset ABS
    elif [ -e "`dirname "$0"`$OFFSET" ]; then
        # Found, probably called absolutely.
        cd "`dirname "$0"`$OFFSET"
        JENKINS_HOME="`pwd`"
    fi;
fi;

# Set JENKINS_URL, JENKINS_KEY, JENKINS_PUB, JENKINS_USER
source "$JENKINS_HOME/etc/jenkins-cli.conf"

echo java -jar "$JENKINS_HOME/lib/jenkins-cli.jar" -ssh -user "$JENKINS_USER" -i "$JENKINS_KEY" -s "$JENKINS_URL" $*

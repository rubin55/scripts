#!/usr/bin/env bash

# Set platform, for WSL set platform to 'windows'. instead of 'linux'.
# Common values: darwin, bsd, gnu/linux, linux, unix, windows.
platform=$(uname -s | tr '[:upper:]' '[:lower:]')
[[ "$(uname -r)" =~ "Microsoft" ]] && platform=windows

# Print stuff to stdout.
print() {
    printf "%s\n" "$@"
}

# Print stuff to stderr.
error() {
    print "$@" 1>&2
}

# A simple help message.
usage() {
    print "Usage: $(basename "$0") -d <comma-separated list of databases>"
    print ""
    print "    -a           Act as-if. don't actually send PGO commands, just"
    print "                 echo them to stdout."
    print "    -d databases A comma-separated list of database names, no"
    print "                 spaces. These names should correspond to"
    print "                 Crunchytools PGO cluster names."
    print "    -n namespace Namespace to pass along to pgo-backup.sh. If not"
    print "                 set, the \$NAMESPACE environment variable is used."
    print "    -r retention Retention count. Defaults to 3 if not specified."
    print "                 Warning: setting retention count to 1 will clean"
    print "                 up all pre-existing full, diff and incr backups."
    print "    -s timeout   Seconds to wait for backup to finish. Defaults to"
    print "                 3600. Only used when -w is passed also."
    print "    -t type      The type of backup to do. Can be full, diff or"
    print "                 incr. If unspecified, will be a full on the 1st"
    print "                 of the month, a differential on Sundays and"
    print "                 incrementals on any other day."
    print "    -w           Wait. wait for backup to finish instead of simply"
    print "                 sending the backup command asynchronously."
    print "    -h           Display help."
    print ""
    print "You can get a list of PGO PostgreSQL clusters for a namespace"
    print "called \"example\" as follows:"
    print ""
    print "    pgo show cluster --all -n example"
    print ""
    exit 1
}

# Get date in seconds since epoch.
seconds() {
    # Example dateString: 2020-09-01 15:06:25 +0200
    # Date command: date +"%Y-%m-%d %T %z"
    local dateString=$1

    if [[ "$platform" == linux ]]; then
        date -d "$dateString"  +"%s"
    elif [[ "$platform" == darwin ]]; then
        date -j -f "%Y-%m-%d %T %z" "$dateString" +"%s"
    else
        error "Error: unknown platform, I don't know how to get date in seconds."
        return 1
    fi
}

# Chop last word from sentence.
chop() {
   echo "${@:1:$#-1}"
}

# Do some getopt magic.
while getopts "d:n:r:s:t:ahw" arg; do
    case $arg in
        a)
            asif="echo"
            error "Acting as-if, will only echo resulting pgo commands.."
            ;;
        d)
            OLD_IFS="$IFS"
            IFS=","
            read -r -a dbs <<< "$OPTARG"
            IFS="$OLD_IFS"
            ;;
        n)
            namespace="$OPTARG"
            ;;
        r)
            retention="$OPTARG"
            ;;
        s)
            timeout="$OPTARG"
            ;;
        t)
            type="$OPTARG"
            ;;
        w)
            wait="true"
            error "Wait was requested, will wait for backup to succeed.."
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# Find pgo-wrapper.sh or bail out.
pgo="$(which pgo-wrapper.sh 2> /dev/null)"
if [[ ! -x "$pgo" ]]; then
    pgo="$(cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )/pgo-wrapper.sh"
    if [[ ! -x $pgo ]]; then
        error "Could not find (or execute) $pgo. Exiting.."
        exit 1
    fi
fi

# Set $NAMESPACE, or bail out - is picked up by pgo-wrapper.sh.
if [[ -z $namespace  && -z $NAMESPACE ]]; then
    error "Error: No namespace specified (-n) and \$NAMESPACE not set."
    exit 1
elif [[ ! -z $namespace  && ! -z $NAMESPACE ]]; then
    error "Warning: namespace was specified (-n) but \$NAMESPACE"
    error "was set also (NAMESPACE=\"$NAMESPACE\")."
    error "Will use namespace passed as argument: \"$namespace\""
    NAMESPACE=$namespace
elif [[ -z $namespace  && ! -z $NAMESPACE ]]; then
    error "Using \$NAMESPACE from environment: \"$NAMESPACE\""
elif [[ ! -z $namespace  && -z $NAMESPACE ]]; then
    error "Using specified namespace: \"$namespace\""
    NAMESPACE=$namespace
fi

# Default retention count. Number represents number
# of full backups that will be kept. For example,
# if the number is 3, and you do a fourth full
# backup, the oldest full backup will be deleted.
# Note: only affects full backups. Incremental and
# differential backups are automatically deleted
# when its related full is deleted.
if [[ -z "$retention" ]]; then
    retention=3
elif ! [[ $retention =~ ^[0-9]+$ ]] ; then
   error "Error: retention needs to be specified as a number. Got: $retention"
   exit 1
fi

# Set a timeout value for wait in seconds.
if [[ -z "$timeout" ]]; then
    timeout=3600
    # Change to result of https://gitlab.com/gitlab-org/gitlab/-/issues/208984
elif ! [[ $timeout =~ ^[0-9]+$ ]] ; then
   error "Error: timeout needs to be specified as a number. Got: $timeout"
   exit 1
fi

# Do a full backup on the first day of the month,
# a differential on Sundays and incrementals on
# any other day.
if [[ -z "$type" ]]; then
    dayname="$(date +%A)"
    dayinmonth="$( date +%d)"

    if [[ $dayinmonth == 01 ]]; then
        type=full
    elif [[ $dayname == Sunday ]]; then
        type=diff
    else
        type=incr
    fi
elif ! [[ $type == 'full' || $type == 'diff' || $type == 'incr' ]]; then
    error "Error: type needs to be either \"full\", \"diff\" or \"incr\". Got: $type"
    exit 1
fi


# Do the work if dbs was set.
if  [[ ! -z "$dbs" ]]; then
    # Log our start time, in date format and seconds since epoch.
    startTime="$(date +"%Y-%m-%d %T %z")"
    startTimeInSeconds="$(seconds "$startTime")"
    print "Start time is $startTime. Requesting \"$type\" backup for: ${dbs[*]}"
    print ""

    # Initialize exitValue to zero.
    exitValue=0

    for db in "${dbs[@]}"; do
        # Check if cluster exists
        if [[ "$("$pgo" show cluster "$db" -n "$NAMESPACE")" == 'No clusters found.' ]]; then
            error "Error: Cluster $db not found, can't backup of $db.."
            continue
        fi

        if [[ $type == full ]]; then
            $asif "$pgo" backup "$db" --backup-opts="--type=$type --repo1-retention-full=$retention" -n "$NAMESPACE"
        else
            $asif "$pgo" backup "$db" --backup-opts="--type=$type" -n "$NAMESPACE"
        fi

        print ""

        #Create a list of all backups to display.
        backupList="$("$pgo" show backup "$db" -n "$NAMESPACE" | grep -A1 -w "full backup:.*\|diff backup:.*\|incr backup:.*")"
        print "Listing currently existing backups for $db:"
        print "$backupList"
        print ""
        print ""

        if [[ $wait == true ]]; then
            # We'll try to wait a maximum of 1 hour for the backup result to appear.
            stopTryingTimeInSeconds=$(($startTimeInSeconds + $timeout))

            # Current time in seconds.
            currentTimeInSeconds="$(seconds "$(date +"%Y-%m-%d %T %z")")"

            while [[ $currentTimeInSeconds -lt stopTryingTimeInSeconds ]]; do

                # Get list of backups of $type.
                typedBackupList="$("$pgo" show backup "$db" -n "$NAMESPACE" | grep -A1 -w "$type backup:.*")"
                lastBackupOfMyType="$(echo "$typedBackupList" | tail -2)"

                # Get start time of last backup of $type.
                if [[ -z "$lastBackupOfMyType" ]]; then
                    retrievedStartTime="1970-01-01 00:00:00 +0000"
                else
                    retrievedStartTime=$(chop $(echo "$lastBackupOfMyType" \
                    | grep ' timestamp start/stop: ' \
                    | sed -e 's/.*timestamp start\/stop: \(.*\)/\1/' \
                    | cut -d/ -f1
                    ))
                fi

                # Update currentTimeInSeconds.
                currentTimeInSeconds="$(seconds "$(date +"%Y-%m-%d %T %z")")"

                # Convert start time of last backup to seconds.
                retrievedStartTimeInSeconds="$(seconds "$retrievedStartTime")"

                # If our startTime is greater the retrieved, we're not done yet.
                # If our startTime is less than the retrieved, we have found a
                # backup of our $type that is newer than our startTime -> assume
                # backup succeeded.
                if [[ $startTimeInSeconds -gt $retrievedStartTimeInSeconds ]]; then
                    remaining=$((stopTryingTimeInSeconds - $currentTimeInSeconds))
                    [[ $remaining -lt 0 ]] && remaining=0
                    error "Waiting for backup of $db to appear ($remaining seconds remaining).."
                    if [[ $currentTimeInSeconds -ge stopTryingTimeInSeconds ]]; then
                        error "Backup request was succesfully sent, but backup of $db did"
                        error "not appear before timeout was reached ($timeout seconds)."
                        exitValue=$((exitValue+1))
                    else
                        sleep 10
                    fi
                else
                    print ""
                    print "Backup appeared for $db:"
                    print "$lastBackupOfMyType"
                    break
                fi
            done
        fi
    done

    # Exit with accumulated exit value. 0 == success, >0 = error.
    exit $exitValue
else
    error "Error: Please specify which databases to backup"
    usage
    exit 1
fi


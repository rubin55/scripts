#!/usr/bin/env sh
if [ -n "$1" ]; then
    export extra_arguments="$*"
fi

kubectl describe ingress $extra_arguments --show-events=false | awk 'BEGIN {a=0;}; /^Rules:/ {a=1; next}; /^Annotations:/ {a=0; next}; /^  (Host|----)/ {next}; /^  [a-z]/ {i=1; gsub(/ /, "", $0); CURR=$0; next}; {if(a>0) printf "%-50s %-40s %-40s %s\n", CURR, $1, $2, $3}' | sort -k 1,2
#

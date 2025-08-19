#!/usr/bin/env bash

# Arguments.
signal_name="$(echo "$1" | tr 'a-z' 'A-Z')"
program_or_pid="$2"

# A list of valid signal names.
readarray -t signal_list < <(
  kill -l |
  sed -E 's/[[:space:]]*[0-9]+\) / /g' |
  tr ' ' '\n' |
  sed '/^$/d;s/^SIG//' |
  sort -u
)

# Print stuff to stdout.
print() {
  printf "$@\n"
}

# Print stuff to stderr.
error() {
  print "$@" 1>&2
}

if [[ ! " ${signal_list[*]} " =~ [[:space:]]${signal_name}[[:space:]] ]]; then
  error "Error: signal '$signal_name' is not a valid signal name"
  exit 1
fi

# Check if number or program name, create pids array.
is_number='^[0-9]+$'
if [[ $program_or_pid =~ $is_number ]]; then
  pids=($program_or_pid)
  if ! ps -p $pids > /dev/null 2>&1; then
    error "No running process found with pid $program_or_pid"
    exit 2
  fi
else
  readarray -t pids < <(pidof $program_or_pid)
  if (( ${#pids[@]} == 0 )); then
    error "No pid(s) found for program named $program_or_pid"
    exit 3
  fi
fi

print "Sending $signal_name to $pids"
kill -s $signal_name $pids

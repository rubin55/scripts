#!/usr/bin/env bash

root="$1"

if [ ! -d "$root" ]; then
  echo "Please specify a directory to recursively check for git repositories."
  echo "Will return name of repository if changes detected."
  exit 1
fi

# Define output file, make sure it's non-existing.
output=/tmp/git-dirstatus.out
rm -f "$output"

# What are we working on, initialize counters.
gitdirs="$(find "$root" -type d -name .git)"
gitdirs_count=$(echo "$gitdirs" | wc -l)
count=1

# Do the work.
for gitdir in $gitdirs; do
  echo -ne "Checking ${count} of ${gitdirs_count}.."'\r' 1>&2
  repo=$(basename $(dirname $gitdir))
  cd "$gitdir/.."
  check=$(git status -s)
  if [ "$check" ]; then
    echo "$repo" >> "$output"
  fi
  cd - >/dev/null
  ((count=count+1))
done

# Neccessary to end the checking counter output.
echo "" 1>&2

# If we have output, print it, and cleanup.
[ -e "$output" ] && cat "$output"
rm -f "$output"

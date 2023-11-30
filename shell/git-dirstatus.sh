#!/usr/bin/env bash

root="$1"

if [ ! -d "$root" ]; then
  echo "Please specify a directory to recursively check for git repositories."
  echo "Will return name of repository if changes detected."
  exit 1
fi

# Define output files, make sure it's non-existing.
right=/tmp/git-dirupdate.right
wrong=/tmp/git-dirupdate.wrong
rm -f "$right" "$wrong"

# What are we working on, initialize counters.
gitdirs="$(find "$root" -type d -name .git)"
gitdirs_count=$(echo "$gitdirs" | wc -l)
count=1

# Do the work.
for gitdir in $gitdirs; do
  echo -ne "Checking ${count} of ${gitdirs_count}.."'\r' 1>&2
  repo=$(basename $(dirname $gitdir))
  cd "$gitdir/.."
  
  # Execute git status; if not exit 0, something went
  # wrong. If exit 0, then check if we have output. If
  # we do, something changed so tell us about it.
  check="$(git status -s 2>&1)"
  if [ $? != 0 ]; then
    echo "$repo" >> "$wrong"
  else
    if [ "$check" ]; then
      echo "$repo" >> "$right"
    fi
  fi
  cd - >/dev/null
  ((count=count+1))
done

# Neccessary to end the checking counter output.
echo "" 1>&2

# If we have output, print it, and cleanup.
if [ -e "$right" ]; then
  echo ""
  echo "The following repositories have changes:" 1>&2  
  cat "$right"
fi

if [ -e "$wrong" ]; then 
  echo ""
  echo "The following repositories had errors while trying to check status:" 1>&2
  cat "$wrong" 1>&2
fi

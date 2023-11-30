#!/usr/bin/env bash

root="$1"

if [ ! -d "$root" ]; then
  echo "Please specify a directory to recursively check for git repositories."
  echo "Will update each repository and return the name of any updated repositories."
  exit 1
fi

# Define output files, make sure it's non-existing.
right=/tmp/git-dirupdate.right
wrong=/tmp/git-dirupdate.wrong
rm -f "$right" "$wrong"

# What are we working on, initialize counters.
readarray -d '' gitdirs < <(find "$root" -type d -name .git -print0)
count=1

# Do the work.
for gitdir in "${gitdirs[@]}"; do
  echo -ne "Checking ${count} of ${#gitdirs[@]}.."'\r' 1>&2
  repo="$(basename "$(dirname "$gitdir")")"
  cd "$gitdir/.."
  
  # Execute git pull; if not exit 0, it's wrong.
  # If exit 0, then check if output indicates it's
  # up-to-date, if not, tell us we actually updated.
  check="$(git pull --all 2>&1)"
  if [ $? != 0 ]; then
    echo "$repo" >> "$wrong"
  else
    echo "$check" | grep -q 'Already up to date.'
    if [ $? != 0 ]; then
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
  echo "" 1>&2
  echo "The following repositories were updated:" 1>&2  
  cat "$right"
fi

if [ -e "$wrong" ]; then 
  echo "" 1>&2
  echo "The following repositories had errors while trying to update:" 1>&2
  cat "$wrong" 1>&2
fi


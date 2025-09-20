#!/usr/bin/env bash

root="$1"

if [ ! -d "$root" ]; then
  echo "Please specify a directory to recursively check for git repositories."
  echo "Will list each repository."
  exit 1
fi

# Define output files, make sure it's non-existing.
right=/tmp/git-dirlist.right
wrong=/tmp/git-dirlist.wrong
rm -f "$right" "$wrong"

# What are we working on, initialize counters.
readarray -d '' gitdirs < <(find "$root" -type d -name .git -print0)
count=1

# Do the work.
for gitdir in "${gitdirs[@]}"; do
  echo -ne "Checking ${count} of ${#gitdirs[@]}.."'\r' 1>&2
  repo="$(echo "$gitdir" | sed 's|^\./||; s|/\.git$||')"
  cd "$repo"
  
  # Check if directory is actually a valid git repo.
  check="$(git rev-parse --is-inside-work-tree 2>&1)"
  if [ $? != 0 ]; then
    echo "$repo" >> "$wrong"
  else
    echo "$repo" >> "$right"
  fi
  cd - >/dev/null
  ((count=count+1))
done

# Neccessary to end the checking counter output.
echo "" 1>&2

# If we have output, print it, and cleanup.
if [ -e "$right" ]; then
  echo "" 1>&2
  echo "The following repositories were found:" 1>&2  
  cat "$right"
fi

if [ -e "$wrong" ]; then 
  echo "" 1>&2
  echo "The following repositories where found but had errors:" 1>&2
  cat "$wrong" 1>&2
fi

#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$HOME/.bash_functions"

build_dir="$HOME/Packaging/Build"

# Format a duration in seconds. Returns 1 (skip) for 1s or less.
format.duration() {
  local sec=$1
  if (( sec <= 1 )); then
    return 1
  elif (( sec < 60 )); then
    printf '%d seconds' "$sec"
  else
    printf '%d minutes' "$(( sec / 60 ))"
  fi
}

# Named filter groups. Edit to add your own.
case "$1" in
  regular) filter() { grep -vE -- '-git|-hg|broken/'; } ;;
  latest)  filter() { grep -vE -- 'broken/|llama|gguf|nvidia' | grep -E -- '-git|-hg'; } ;;
  llama)   filter() { grep -v -- 'broken/' | grep -E -- 'llama|gguf'; } ;;
  *)
    echo "usage: $0 <group>"
    echo "groups: regular, latest, llama"
    [[ -z "$1" ]] && exit 0
    exit 1
    ;;
esac

group=$1
list_file="/tmp/build-packages.$group.list"
list_read="$list_file.read"
time_file="/tmp/build-packages.$group.times"

# Both files survive an interrupted run: the list holds what is left to
# build, the times file holds "seconds|name" for everything built so far.
if [[ ! -s "$list_file" ]]; then
  git-dirlist.sh "$build_dir" 2>/dev/null | sort -u | filter > "$list_file"
  : > "$time_file"
fi

# Drop a finished package from the work list.
list.done() {
  grep -vxF "$1" "$list_file" > "$list_file.tmp" && mv "$list_file.tmp" "$list_file"
}

# Total and top ten, over this run plus any interrupted earlier ones. A
# package built more than once (fixed after a failure) counts only its
# last attempt.
report.times() {
  [[ -s "$time_file" ]] || return 0
  local times total_sec total_dur longest sec name dur
  times=$(awk -F'|' '{ t[$2] = $1 } END { for (k in t) print t[k] "|" k }' "$time_file" | sort -t'|' -k1 -rn)
  total_sec=$(awk -F'|' '{ s += $1 } END { print s+0 }' <<< "$times")

  if total_dur=$(format.duration "$total_sec"); then
    echo "Total time spent: ~$total_dur"
  fi

  longest=$(head -n 10 <<< "$times" | while IFS='|' read -r sec name; do
    dur=$(format.duration "$sec") && printf '   - %s: %s\n' "$name" "$dur"
  done)

  if [[ -n "$longest" ]]; then
    echo "Longest running:"
    printf '%s\n' "$longest"
  fi
}

cp "$list_file" "$list_read"

c=$(wc -l < "$list_read")
if (( c == 0 )); then
  log.error "No packages to build for group '$group'."
  rm -f "$list_read"
  exit 1
fi

first=$(basename "$(head -n 1 "$list_read")")
log.info "Start building $c packages, starting with $first. CTRL-C to abort..."
sleep 3

# Keep the report on CTRL-C too; the list and times files stay behind so a
# later run picks up where this one stopped.
trap 'echo; title.line; report.times; exit 130' INT

n=0
# Read the list on fd 3 so makepkg and pacman keep the terminal on stdin
# and can still prompt for build dependencies.
while IFS= read -r p <&3 || [[ -n "$p" ]]; do
  n=$((n+1))
  display="$(basename "$(dirname "$p")")/$(basename "$p")"
  title.append " ($n/$c: $display)"
  title.line "($n/$c: $display)"

  start=$SECONDS
  (
    cd "$p" || exit 1
    makepkg -cCs
  )
  rc=$?
  printf '%d|%s\n' "$(( SECONDS - start ))" "$display" >> "$time_file"

  # 13 is "package already built", which is not a failure.
  if (( rc != 0 && rc != 13 )); then
    log.error "$p did not go well, please fix..."
    failed=1
    break
  fi
  list.done "$p"
done 3< "$list_read"

title.line
report.times

# Cleanup.
if ! (( ${failed:-0} )); then
  title.append ""
  rm -f "$list_file" "$time_file"
fi
rm -f "$list_file.tmp" "$list_read"

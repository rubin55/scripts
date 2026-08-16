#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$HOME/.bash_functions"

build_dir="$HOME/Packaging/Build"
known_groups="all regular devel linux llama nvidia chromium custom others mine"

# Print a line, optionally in a named colour: <text> [colour].
color.print() {
  local -A colors=(
    [black]=30         [red]=31            [green]=32         [yellow]=33
    [blue]=34          [magenta]=35        [cyan]=36          [white]=37
    [bright-black]=90  [bright-red]=91     [bright-green]=92  [bright-yellow]=93
    [bright-blue]=94   [bright-magenta]=95 [bright-cyan]=96   [bright-white]=97
  )
  local code=${2:+${colors[$2]}}
  if [[ -n $code ]]; then
    printf '\e[%sm%s\e[0m\n' "$code" "$1"
  else
    printf '%s\n' "$1"
  fi
}

# The selected groups combined, in the order given, without duplicates.
filter() {
  local input g
  input=$(cat)
  for g in "${groups[@]}"; do filter.group "$g" <<< "$input"; done | awk '!seen[$0]++'
}

# Named filter groups. Add your own here and to $known_groups.
filter.group() {
  case "$1" in
    all)      grep -vE -- 'broken/' ;;
    regular)  grep -vE -- 'broken/|chromium|linux-tachyon|sunshine|-git|-hg' ;;
    devel)    grep -vE -- 'broken/|chromium|llama.cpp-vulkan|llama.cpp-cuda|gguf|nvidia|cuda|linux-tachyon|sunshine' | grep -E -- '-git|-hg' ;;
    linux)    grep -vE -- 'broken/|chromium|llama.cpp-vulkan|llama.cpp-cuda|gguf|nvidia|cuda|sunshine'               | grep -E -- 'linux-tachyon' ;;
    llama)    grep -vE -- 'broken/|chromium|nvidia|cuda|linux-tachyon|sunshine' | sort -r                            | grep -E -- 'llama.cpp-vulkan|llama.cpp-cuda|gguf' ;;
    nvidia)   grep -vE -- 'broken/|chromium|llama.cpp-vulkan|gguf|linux-tachyon'                                     | grep -E -- 'nvidia|cuda|sunshine' ;;
    chromium) grep -vE -- 'broken/|llama.cpp-vulkan|llama.cpp-cuda|gguf|nvidia|cuda|linux-tachyon|sunshine'          | grep -E -- 'chromium' ;;
    custom)   grep -vE -- 'broken/|chromium|llama.cpp-vulkan|llama.cpp-cuda|gguf|nvidia|cuda|linux-tachyon|sunshine' | grep -E -- 'custom/' ;;
    others)   grep -vE -- 'broken/|chromium|llama.cpp-vulkan|llama.cpp-cuda|gguf|nvidia|cuda|linux-tachyon|sunshine' | grep -E -- 'others/' ;;
    mine)     grep -vE -- 'broken/|chromium|llama.cpp-vulkan|llama.cpp-cuda|gguf|nvidia|cuda|linux-tachyon|sunshine' | grep -E -- 'mine/' ;;
  esac
}

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

# Drop a finished package from the work list.
list.done() {
  grep -vxF "$1" "$list_file" > "$list_file.tmp" && mv "$list_file.tmp" "$list_file"
}

# Turn a list of paths on stdin into a space separated list of names.
list.names() {
  sed 's|.*/||' | sort | tr '\n' ' ' | sed 's/ $//'
}

# Show what the filter of this group selects, and what it leaves out.
report.filter() {
  local selected included excluded
  selected=$(filter <<< "$all" | sort)
  included=$(list.names <<< "$selected")
  excluded=$(comm -23 <(printf '%s\n' "$all") <(printf '%s\n' "$selected") | list.names)
  report.line "$label" "$included" green
  echo
  report.line Excluded "$excluded" red
}

# One wrapped label line, with the names in the given colour.
report.line() {
  local label=$1 names=$2 color=$3 cols text
  cols=$(tput cols 2>/dev/null || echo 80)
  text=$(fold -s -w "$cols" <<< "$label: ${names:-none}")
  printf '%s: ' "$label"
  color.print "${text#"$label: "}" "$color"
}

# Total and top ten longest builds, last attempt per package.
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

# Show how to call this script and exit with the given status.
usage() {
  echo "usage: $0 <group> [group...]"
  echo "groups: ${known_groups// /, }"
  exit "$1"
}

# Script starts execution here.
[[ $# -eq 0 ]] && usage 0
for g in "$@"; do
  [[ " $known_groups " == *" $g "* ]] || { log.error "Unknown group '$g'."; usage 1; }
done

groups=("$@")
group=$(IFS=+; echo "${groups[*]}")
label=""
for g in "${groups[@]}"; do label+="${label:+, }${g^}"; done

list_file="/tmp/build-packages.$group.list"
list_read="$list_file.read"
time_file="/tmp/build-packages.$group.times"

all=$(git-dirlist.sh "$build_dir" 2>/dev/null | sort -u)

# Both files survive an interrupted run, so a later one can resume.
if [[ ! -s "$list_file" ]]; then
  filter <<< "$all" > "$list_file"
  : > "$time_file"
fi

cp "$list_file" "$list_read"

c=$(wc -l < "$list_read")
if (( c == 0 )); then
  log.error "No packages to build for '${groups[*]}'."
  rm -f "$list_read"
  exit 1
fi

report.filter
echo

first=$(basename "$(head -n 1 "$list_read")")
log.info "Start building $c packages, starting with $first. CTRL-C to abort..."
sleep 8

# Keep the report on CTRL-C; the files stay behind for a resume.
trap 'echo; title.line; report.times; exit 130' INT

# Read on fd 3 so makepkg and pacman keep the terminal on stdin.
n=0
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
    title.line
    log.error "An error occurred in package \"$(basename "$p")\"."
    log.error "Go to \"$p/PKGBUILD\" and fix it."
    log.error "After that you can restart with: $0 ${groups[*]}"
    failed=1
    break
  fi
  list.done "$p"
done 3< "$list_read"

# Only summarise a completed run; a failure keeps its files.
if ! (( ${failed:-0} )); then
  title.line
  report.times
  title.append ""
  rm -f "$list_file" "$time_file"
fi
rm -f "$list_file.tmp" "$list_read"

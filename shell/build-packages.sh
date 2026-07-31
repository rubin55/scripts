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
  git-hg)  filter() { grep -v -- 'broken/' | grep -E -- '-git|-hg'; } ;;
  *)
    echo "usage: $0 <group>"
    echo "groups: regular, git-hg"
    [[ -z "$1" ]] && exit 0
    exit 1
    ;;
esac

list_file="/tmp/build-packages.$1.list"

if [[ ! -s "$list_file" ]]; then
  git-dirlist.sh "$build_dir" 2>/dev/null | sort -u | filter > "$list_file"
fi

list_read="$list_file.read"
cp "$list_file" "$list_read"

c=$(wc -l < "$list_read")
if [[ "$c" -eq 0 ]]; then
  log.error "No packages to build for group '$1'."
  rm -f "$list_read"
  exit 1
fi

first=$(basename "$(sed -n '1p' "$list_read")")
log.info "Start building $c packages, starting with $first. CTRL-C to abort..."
sleep 3

record=()
total_sec=0
n=0
while IFS= read -r p || [[ -n "$p" ]]; do
  n=$((n+1))
  display="$(basename "$(dirname "$p")")/$(basename "$p")"
  title.append " ($n/$c: $display)"
  start=$SECONDS
  build_out=$(mktemp)
  build_err=$(mktemp)
  title.line "($n/$c: $display)"
  (
    cd "$p" || exit 1
    makepkg -cCs
  ) 2> "$build_err" | tee "$build_out"
  rc=${PIPESTATUS[0]}
  elapsed=$(( SECONDS - start ))
  out_lines=$(wc -l < "$build_out")
  rm -f "$build_out"
  total_sec=$(( total_sec + elapsed ))
  record+=( "$elapsed|$display" )
  if [[ $rc -eq 13 ]]; then
    if [[ "$out_lines" -eq 0 ]]; then
      printf '\033[2A\033[J\033[A'
    else
      cat "$build_err" >&2
      echo
    fi
    rm -f "$build_err"
    grep -vxF "$p" "$list_file" > "$list_file.tmp" && mv "$list_file.tmp" "$list_file"
    continue
  fi
  cat "$build_err" >&2
  rm -f "$build_err"
  if [[ $rc -ne 0 ]]; then
    log.error "$p did not go well, please fix..."
    failed=1
    break
  fi
  # Build succeeded, remove p from list.
  grep -vxF "$p" "$list_file" > "$list_file.tmp" && mv "$list_file.tmp" "$list_file"
  echo
done < "$list_read"

title.line

if total_dur=$(format.duration "$total_sec"); then
  echo "Total time spent: ~$total_dur"
fi

longest=$(printf '%s\n' "${record[@]}" | sort -t'|' -k1 -rn | head -n 10 | while IFS='|' read -r sec name; do
  if dur=$(format.duration "$sec"); then
    printf '   - %s: %s\n' "$name" "$dur"
  fi
done)

if [[ -n "$longest" ]]; then
  echo "Longest running:"
  printf '%s\n' "$longest"
fi

# Cleanup.
if ! (( ${failed:-0} )); then
  title.append ""
  rm -f "$list_file"
fi
rm -f "$list_file.tmp" "$list_read"

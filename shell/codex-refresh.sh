#!/usr/bin/env bash

# Restart each interactive Codex in a tmux pane, and resume its session.
# Codex reads the terminal colors only when it starts, so a restart
# gives it the colors of the current theme. It waits for a busy Codex
# for max_wait seconds, and skips it after that time.

max_wait=60

# Let only one refresh run at a time.
exec {lock}> "${XDG_RUNTIME_DIR:-/tmp}/codex-refresh.lock"
flock "$lock"

# Options that take a value, from the help of 'codex resume'.
declare -A takes_value
for option in $(codex resume --help | grep -oE '^ +(-[A-Za-z], )?--[a-z0-9-]+ <' |
  grep -oE -- '-{1,2}[A-Za-z0-9-]+'); do
  takes_value[$option]=1
done

# Print the ID of the first session file that a process has open.
function session_id() {
  local file
  file="$(find "/proc/$1/fd" -lname '*/sessions/*/rollout-*.jsonl' -printf '%l\n' \
    2> /dev/null | sort | head -n 1)"
  file="${file%.jsonl}"
  [[ -n $file ]] && echo "${file: -36}"
}

# Print the options of a Codex command line, quoted for the shell.
# Remove the prompt, the subcommand, the images and the resume options.
function options() {
  local arg keep=()
  while (($#)); do
    arg="$1"
    shift
    case "$arg" in
      --last | --all | --include-non-interactive) ;;
      -i | --image) shift ;;
      -*)
        keep+=("$arg")
        if [[ -n ${takes_value[$arg]} ]]; then
          keep+=("$1")
          shift
        fi
        ;;
    esac
  done
  ((${#keep[@]})) && printf '%q ' "${keep[@]}"
}

# Quit the Codex process in a pane, then start it again with its session.
function refresh() {
  local pane="$1" pane_pid="$2" pid="$3" id argv cmd cwd waited=0
  while tmux capture-pane -p -t "$pane" | grep -q 'to interrupt)'; do
    if ((waited++ >= max_wait)); then
      echo "Skip ${pane}: Codex is busy" >&2
      return
    fi
    sleep 1
  done
  [[ -d /proc/$pid ]] || return
  id="$(session_id "$pid")"
  mapfile -d '' -t argv < "/proc/${pid}/cmdline"
  cmd="codex ${id:+resume $id }$(options "${argv[@]:1}")"
  cwd="$(readlink "/proc/${pid}/cwd")"

  # Keep the pane open when Codex is the pane process.
  [[ $pid == "$pane_pid" ]] && tmux set -p -t "$pane" remain-on-exit on

  # Ctrl+C closes a popup, clears the draft, or quits an idle Codex.
  for _ in {1..3}; do
    tmux send-keys -t "$pane" C-c
    for _ in {1..10}; do
      [[ -d /proc/$pid ]] || break 2
      sleep 0.1
    done
  done
  if [[ -d /proc/$pid ]]; then
    echo "Skip ${pane}: Codex did not quit" >&2
    return
  fi

  # Clear the screen and history, because they keep the old colors.
  # Codex shows the full session again when it resumes.
  echo "${pane}: ${cmd}"
  if [[ $pid == "$pane_pid" ]]; then
    tmux clear-history -t "$pane"
    tmux respawn-pane -t "$pane" -c "$cwd" "$cmd"
    tmux set -p -u -t "$pane" remain-on-exit
  else
    tmux send-keys -t "$pane" -l "clear && ${cmd}"
    tmux send-keys -t "$pane" Enter
  fi
}

# Refresh the top Codex process in each pane, all panes at once.
while read -r pane pane_pid tty; do
  for pid in $(pgrep -x -t "${tty#/dev/}" codex); do
    [[ $(ps -o comm= -p "$(ps -o ppid= -p "$pid" | tr -d ' ')") == codex ]] && continue
    refresh "$pane" "$pane_pid" "$pid" &
  done
done < <(tmux list-panes -a -F '#{pane_id} #{pane_pid} #{pane_tty}' 2> /dev/null)
wait

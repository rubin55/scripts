#!/usr/bin/env bash

# Give programs in tmux panes the Alacritty colors of a mode.
# tmux keeps the terminal colors of its last query, and it does not
# query the terminal again within 30 seconds. With an explicit
# window-style, tmux replies to OSC 10 and 11 with the style colors.
# It also sends a mode 2031 theme report to each pane that asks for it.

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty"

# Print a primary color (background or foreground) of a theme file.
function color() {
  awk -v key="$1" '/^\[/ { primary = ($0 == "[colors.primary]") }
    primary && $1 == key { gsub(/[\047"]/, "", $3); print $3 }' "$2"
}

# Set the window style of the tmux server to the colors of a mode.
function set_style() {
  local theme="${config_dir}/${1}_theme.toml" bg fg
  bg="$(color background "$theme")"
  fg="$(color foreground "$theme")"
  if [[ -z $bg || -z $fg ]]; then
    echo "No primary colors in ${theme}" >&2
    return 1
  fi
  # Do nothing when no tmux server runs.
  tmux has-session 2> /dev/null || return 0
  tmux set -g window-style "fg=${fg},bg=${bg}"
}

if [[ $1 == set && ($2 == dark || $2 == light) ]]; then
  set_style "$2"
else
  echo "Usage: $(basename "$0") set dark|light"
fi

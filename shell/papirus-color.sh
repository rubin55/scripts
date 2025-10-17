#!/usr/bin/env bash

# gnome-accents: gsettings range org.gnome.desktop.interface accent-color
# papirus-folders: papirus-folders -l (key is accent, value is folders)
declare -A colors
colors['blue']='blue'
colors['teal']='teal'
colors['green']='green'
colors['yellow']='yellow'
colors['orange']='orange'
colors['red']='red'
colors['pink']='pink'
colors['purple']='violet'
colors['slate']='bluegrey'

# Get current Gnome accent color.
current_accent="$(gsettings get org.gnome.desktop.interface accent-color | sed "s|'||g")"

case "$1" in
  list|ls)
  papirus-folders -l | grep -v List
  ;;
  get)
  papirus-folders -l | grep '>' | cut -d ' ' -f 3
  ;;
  set)
  papirus-folders -C "$2"
  ;;
  auto)
  papirus-folders -C "${colors["$current_accent"]}"
  ;;
  *)
  echo "Usage: $(basename "$0") list|get|set <color>|auto"
  ;;
esac
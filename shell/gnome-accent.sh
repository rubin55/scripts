#!/usr/bin/env bash

case "$1" in
  list|ls)
  gsettings range org.gnome.desktop.interface accent-color | grep -wv enum | sed "s|'||g"
  ;;
  get)
  gsettings get org.gnome.desktop.interface accent-color | sed "s|'||g"
  ;;
  set)
  gsettings set org.gnome.desktop.interface accent-color "$1"
  ;;
  *)
  echo "Usage: $(basename "$0") list|get|set <color>"
  ;;
esac
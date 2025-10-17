#!/usr/bin/env bash

case "$1" in
  list|ls)
  gsettings range org.gnome.desktop.interface accent-color | grep -wv enum
  ;;
  get)
  gsettings get org.gnome.desktop.interface accent-color 
  ;;
  set)
  gsettings set org.gnome.desktop.interface accent-color "$1"
  ;;
  *)
  echo "Usage: $(basename "$0") list|get|set <color>"
  ;;
esac
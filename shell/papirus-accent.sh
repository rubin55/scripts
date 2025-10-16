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

accent="$(gsettings get org.gnome.desktop.interface accent-color | sed "s|'||g")"
echo "papirus-accent: Got '$accent' accent color from 'Gnome' ..."
papirus-folders -C "${colors["$accent"]}"
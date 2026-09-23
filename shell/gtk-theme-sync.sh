#!/usr/bin/env bash

# Sync the GTK3, qt5ct and qt6ct theme with the GNOME color scheme.

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
unit_name="gtk-theme-sync.service"
unit_file="${config_dir}/systemd/user/${unit_name}"

# Set the themes to match the current color scheme.
function sync_themes() {
  if [[ $(gsettings get org.gnome.desktop.interface color-scheme) == *dark* ]]; then
    gtk_theme="Adwaita-dark" qt_style="Adwaita-Dark"
  else
    gtk_theme="Adwaita" qt_style="Adwaita"
  fi

  gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"

  # Use the palette of the style, so it follows light and dark.
  sed -i -e "s|^style=.*|style=${qt_style}|" -e "s|^custom_palette=.*|custom_palette=false|" \
    "${config_dir}/qt5ct/qt5ct.conf" "${config_dir}/qt6ct/qt6ct.conf"
}

# Sync now, then again on each color scheme change.
function listen() {
  # Run the loop in this shell, without a forked subshell.
  shopt -s lastpipe
  sync_themes
  gsettings monitor org.gnome.desktop.interface color-scheme | while read -r _; do
    sync_themes
  done
}

# Install, enable and start the user unit.
function enable_unit() {
  mkdir -p "$(dirname "$unit_file")"
  cat > "$unit_file" <<EOF
[Unit]
Description=Sync GTK3 and Qt theme with GNOME color scheme
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=$(realpath "$0") listen
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now "$unit_name"
}

# Stop, disable and remove the user unit.
function disable_unit() {
  systemctl --user disable --now "$unit_name"
  rm -f "$unit_file"
  systemctl --user daemon-reload
}

case "$1" in
  listen)
  listen
  ;;
  enable)
  enable_unit
  ;;
  disable)
  disable_unit
  ;;
  *)
  echo "Usage: $(basename "$0") listen|enable|disable"
  ;;
esac

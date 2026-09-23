#!/usr/bin/env bash

# Sync GTK3, Qt, Alacritty and Neovim with the GNOME color scheme.

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
script="$(realpath "${BASH_SOURCE[0]}")"
unit_name="theme-sync.service"
unit_file="${config_dir}/systemd/user/${unit_name}"

# Things to sync, each has a sync_<name> function below.
targets=(gtk qt alacritty neovim)

# Print the current mode: dark or light.
function get_mode() {
  if [[ $(gsettings get org.gnome.desktop.interface color-scheme) == *dark* ]]; then
    echo dark
  else
    echo light
  fi
}

# Set the GTK3 theme.
function sync_gtk() {
  local theme="Adwaita"
  [[ $1 == dark ]] && theme="Adwaita-dark"
  gsettings set org.gnome.desktop.interface gtk-theme "$theme"
}

# Set the qt5ct and qt6ct style, and use the palette of the style.
function sync_qt() {
  local style="Adwaita"
  [[ $1 == dark ]] && style="Adwaita-Dark"
  sed -i -e "s|^style=.*|style=${style}|" -e "s|^custom_palette=.*|custom_palette=false|" \
    "${config_dir}/qt5ct/qt5ct.conf" "${config_dir}/qt6ct/qt6ct.conf"
}

# Set the Alacritty mode, and keep the light and dark themes.
function sync_alacritty() {
  [[ -e ${config_dir}/alacritty/alacritty.toml ]] || return 0
  "${script%/*}/alacritty-theme.sh" set "$1"
}

# Set 'background' in each running Neovim through its server socket.
# The OptionSet autocmd in appearance.lua then sets the colorscheme.
function sync_neovim() {
  local socket
  for socket in "${XDG_RUNTIME_DIR}"/nvim*; do
    [[ -S $socket ]] || continue
    timeout 2 nvim --server "$socket" --remote-expr \
      "&background ==# '$1' ? '' : execute('set background=$1')" > /dev/null 2>&1
  done
}

# Sync all targets with the current mode.
function sync_themes() {
  local mode target
  mode="$(get_mode)"
  for target in "${targets[@]}"; do
    "sync_${target}" "$mode"
  done
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
Description=Sync themes with GNOME color scheme
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=${script} listen
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

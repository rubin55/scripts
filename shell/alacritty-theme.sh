#!/usr/bin/env bash

# A few variables.
config_dir="${HOME}/.config/alacritty"
config_file="${config_dir}/alacritty.toml"
active_mode="$(grep -E '~/.config/alacritty/(dark|light)_theme.toml' "${config_file}" | grep -oE '(dark|light)')"
active_theme=$(readlink "${config_dir}/${active_mode}_theme.toml" | sed "s|\.toml||")
themes_dir="${config_dir}/themes/themes"
mapfile -t themes < <(find "${themes_dir}" -type f -printf "%f\n")

# Print stuff to stdout.
function print() {
  printf "$@\n"
}

# Print stuff to stderr.
function error() {
  print "$@" 1>&2
}

# Title case something.
function title_case() {
  print "$1" | tr '[:upper:]' '[:lower:]' | awk '{for(j=1;j<=NF;j++){ $j=toupper(substr($j,1,1)) substr ($j,2) }}1'
}

# Apply a mode and/or theme.
function apply_theme() {
  local mode="$1"
  local theme="$2"

  if [[ -n $mode ]]; then
    sed -Ei "s|~/.config/alacritty/${active_mode}_theme.toml|~/.config/alacritty/${mode}_theme.toml|" "${config_file}"
    sed -Ei "s|decorations_theme_variant = \"$(title_case ${active_mode})\"|decorations_theme_variant = \"$(title_case ${mode})\"|" "${config_file}"
  fi

  if [[ -n $theme ]]; then
    relative_path="$(echo "${themes_dir}" | sed "s|${config_dir}/||")"
    ln -sf "${relative_path}/${theme}.toml" "${config_dir}/${mode}_theme.toml"
    touch "${themes_dir}/${theme}.toml"
  fi
}

# Switch from dark to light and vice-versa.
function switch_theme {
  target_mode=$([[ $active_mode == dark ]] && echo light || echo dark)
  apply_theme "${target_mode}"
}

# List available themes.
function list_themes() {
  printf "%s\n" "${themes[@]}" | sed "s|\.toml||" | sort | column -m
}

# Update the themes repository.
function update_themes {
  git --git-dir="${config_dir}/themes/.git" --work-tree="${config_dir}/themes" pull
}

# Show usage help.
function usage() {
  print "Usage: $(basename "$0") list|set[light|dark <theme>]|switch|update"
}

# Main case statement.
case "$1" in
  list)
  list_themes
  ;;
  set)
  mode="$2"
  [[ $mode == "dark" || $mode == "light" ]] && valid_mode="true" || valid_mode="false"
  
  theme="$3"
  [[ " ${themes[@]} " =~ " ${theme}.toml " ]] && valid_theme="true" || valid_theme="false"
  
  if [[ $valid_mode == true && $valid_theme == true ]]; then
    apply_theme "$mode" "$theme"
  else
    [[ $valid_mode == false ]] && error 'Invalid mode specified; should be "dark" or "light"'
    [[ $valid_theme == false ]] && error "Invalid theme specified; check $(basename "$0") list"
    exit 1
  fi
  ;;
  switch)
  switch_theme
  ;;
  update)
  update_themes
  ;;  
  *)
  usage
  ;;
esac


#!/usr/bin/env bash

# Set the Mattermost theme on each server of Mattermost Desktop.
# It uses the session token in the cookies of Mattermost Desktop.
# It also reloads the pages, so the window frame gets the new theme.
# This needs the remote debugging port, run 'configure' to set it.

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/Mattermost"
desktop_file="mattermost-desktop.desktop"
debug_port=9223
dark_theme="Indigo"
light_theme="Quartz"

# Arguments for Mattermost Desktop in the user desktop file.
flags=(
  --remote-debugging-port="$debug_port"
  --enable-features=WaylandWindowDecorations
  --disable-features=GlobalShortcutsPortal,WaylandFractionalScaleV1
)

# Print the value of a cookie for a host.
function cookie() {
  sqlite3 "file:${config_dir}/Cookies?immutable=1" \
    "select value from cookies where host_key in ('$1', '.$1') and name = '$2'"
}

# Set the theme on each server that has a session.
function set_theme() {
  local theme="$light_theme" url host token user
  [[ $1 == dark ]] && theme="$dark_theme"
  for url in $(jq -r '.servers[].url' "${config_dir}/config.json"); do
    url="${url%/}"
    host="${url#*://}"
    host="${host%%/*}"
    token="$(cookie "$host" MMAUTHTOKEN)"
    user="$(cookie "$host" MMUSERID)"
    [[ -n $token ]] || continue
    # Mattermost gets the other theme colors from the type.
    jq -nc --arg u "$user" --arg t "$theme" \
      '[{user_id: $u, category: "theme", name: "", value: ({type: $t} | tojson)}]' |
      curl -sf -m 10 -o /dev/null -X PUT -H "Authorization: Bearer ${token}" \
        --data @- "${url}/api/v4/users/me/preferences" ||
      echo "Failed to set theme on ${url}" >&2
  done
}

# Send a DevTools command of less than 126 bytes to a WebSocket URL.
function devtools() {
  local addr="${1#ws://}" fd line
  addr="${addr%%/*}"
  exec {fd}<> "/dev/tcp/${addr%:*}/${addr#*:}" || return
  printf 'GET /%s HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: AAAAAAAAAAAAAAAAAAAAAA==\r\nSec-WebSocket-Version: 13\r\n\r\n' \
    "${1#ws://*/}" "$addr" >&"$fd"
  # Skip the response headers.
  while read -r -t 2 -u "$fd" line && [[ $line != $'\r' ]]; do :; done
  # Send one text frame with a zero mask, then wait for the reply.
  printf "\\x81\\x$(printf %x $((0x80 + ${#2})))\\0\\0\\0\\0%s" "$2" >&"$fd"
  read -r -t 2 -d '}' -u "$fd" line
  exec {fd}>&-
}

# Reload the server pages, so the window frame gets the new theme.
function reload_pages() {
  local ws
  for ws in $(curl -sf -m 2 "http://127.0.0.1:${debug_port}/json/list" |
    jq -r '.[] | select(.url | startswith("http")) | .webSocketDebuggerUrl'); do
    devtools "$ws" '{"id":1,"method":"Page.reload"}'
  done
}

# Copy the system desktop file to the user, with the flags added.
function configure() {
  local target="${XDG_DATA_HOME:-$HOME/.local/share}/applications/${desktop_file}"
  mkdir -p "${target%/*}"
  sed "s|^Exec=mattermost-desktop|& ${flags[*]}|" \
    "/usr/share/applications/${desktop_file}" > "$target"
}

if [[ $1 == set && ($2 == dark || $2 == light) ]]; then
  set_theme "$2"
  reload_pages
elif [[ $1 == configure ]]; then
  configure
else
  echo "Usage: $(basename "$0") set dark|light|configure"
fi

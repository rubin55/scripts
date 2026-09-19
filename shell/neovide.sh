#!/usr/bin/env bash

script_dir=$(cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)
nvim_wrapper="$script_dir/nvim.sh"
neovide='/usr/bin/neovide'

# Socket path for the running nvim server. The name matches the
# nvim-mcp.*.sock glob that nvim-mcp looks for in manual mode.
socket="${XDG_RUNTIME_DIR:-/tmp}/nvim-mcp.${USER}.sock"

# Check if nvim is running for the current user with our socket.
if [ -S "$socket" ] && pgrep -u "$USER" -x nvim > /dev/null 2>&1; then
    exec "$nvim_wrapper" "$@"
else
    # Start a fresh neovide; tell the embedded nvim to listen on our socket.
    exec "$neovide" "$@" -- --listen "$socket"
fi

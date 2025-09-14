#!/usr/bin/env bash

# Determine chromium-flags.conf location.
if [[ -f "$HOME/.config/chromium/chromium-flags.conf" ]]; then
  CHROMIUM_FLAGS_FILE="$HOME/.config/chromium/chromium-flags.conf"
else
  CHROMIUM_FLAGS_FILE="/etc/chromium/chromium-flags.conf"
fi

if [ -f "$CHROMIUM_FLAGS_FILE" ]; then
  echo "Using flags specified in $CHROMIUM_FLAGS_FILE"
  CHROMIUM_USER_FLAGS=$(cat "$CHROMIUM_FLAGS_FILE" | grep '^\(#.*\)\?$' -v | tr '\n' ' ')
fi

chromium $CHROMIUM_USER_FLAGS "$@"

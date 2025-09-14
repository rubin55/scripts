#!/usr/bin/env bash

# Determine chromium-flags.conf location.
if [[ -f "$HOME/.config/chromium/chromium-flags.conf" ]]; then
  CHROMIUM_FLAGS_FILE="$HOME/.config/chromium/chromium-flags.conf"
  CHROMIUM_FLAGS_FILE_CORRECT_LOCATION=false
elif [[ -f "$HOME/.config/chromium-flags.conf" ]]; then
  CHROMIUM_FLAGS_FILE="$HOME/.config/chromium-flags.conf"
  CHROMIUM_FLAGS_FILE_CORRECT_LOCATION=true
else
  CHROMIUM_FLAGS_FILE="/etc/chromium/chromium-flags.conf"
  CHROMIUM_FLAGS_FILE_CORRECT_LOCATION=false
fi

if [ -f "$CHROMIUM_FLAGS_FILE" ]; then
  CHROMIUM_USER_FLAGS=$(cat "$CHROMIUM_FLAGS_FILE" | grep '^\(#.*\)\?$' -v | tr '\n' ' ')
  echo "Using flags specified in $CHROMIUM_FLAGS_FILE:"
  echo "$CHROMIUM_USER_FLAGS"
fi

if [ "$CHROMIUM_FLAGS_FILE_CORRECT_LOCATION" == "true" ]; then
  chromium "$@"
else
  chromium $CHROMIUM_USER_FLAGS "$@"
fi

#!/usr/bin/env bash

# Custom function definitions.
if [ -f "$HOME/.bash_functions" ]; then
  . "$HOME/.bash_functions"
fi

# Optionally set fontsizes config for user-scaling.sh.
[[ -n $1 ]] && export FONT_SIZE_PREFERENCES_FILE="$1"

# Remove the scaling timer to force re-eval.
rm  -f /tmp/user-scaling.timer

# Re-rerun the scaling utility.
. "$HOME/.profile.d/user-scaling.sh"


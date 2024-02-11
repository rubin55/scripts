#!/usr/bin/env bash

# Custom function definitions.
[[ -f "$HOME/.bash_functions" ]] && source "$HOME/.bash_functions"

# Optionally set fontsizes config for user-scaling.sh.
[[ -n $1 ]] && export FONT_SIZE_PREFERENCES_FILE="$1"

# Remove the scaling timer to force re-eval.
rm  -f /tmp/user-scaling.timer

# Re-rerun the scaling utility.
source "$HOME/.profile.d/user-scaling.sh"


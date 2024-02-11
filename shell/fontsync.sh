#!/usr/bin/env bash

# Set fontsizes config for user-scaling.sh.
[[ -n $1 ]] && FONT_SIZE_PREFERENCES_FILE="$1"

# Remove the scaling timer to force re-eval.
rm  -f /tmp/user-scaling.timer

# Re-rerun the scaling utility.
source "$HOME/.profile.d/user-scaling.sh"

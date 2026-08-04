#!/usr/bin/env bash

# Wrapper for jira: fills in credentials from tipi.py if not set.
# Sourced:  only exports the env vars into the current shell.
# Executed: fills in the vars if unset and runs the jira binary.

if [[ -z "$JIRA_API_TOKEN" || -z "$JIRA_AUTH_TYPE" ]]; then
    export JIRA_AUTH_TYPE=bearer
    export JIRA_API_TOKEN="$(tipi.py nl.ictu-sd.jira rusim-default-token-pat)"
fi

# Run the binary only when executed, not sourced.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    exec /usr/bin/jira "$@"
fi

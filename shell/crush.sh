#!/usr/bin/env bash
set -ueo pipefail

readonly HASH=$(pwd | sha256sum | cut -d' ' -f1)
readonly STATE_PATH="${HOME}/.cache/crush/projects/${HASH}"

crush -D "${STATE_PATH}" "${@}"

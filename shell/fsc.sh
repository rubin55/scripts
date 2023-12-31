#!/usr/bin/env bash

set -euo pipefail

sdk_path=$(dotnet --list-sdks | sort --version-sort --reverse | head -n 1 | sed -E 's/^([^ ]+) \[(.+)\]$/\2\/\1/')
fsc_dll="${sdk_path}/FSharp/fsc.dll"

if [[ ! -f "${fsc_dll}" ]]; then
  echo "Could not find fsc.dll at ${fsc_dll}" >&2
  exit 1
fi

dotnet "${fsc_dll}" "$@"

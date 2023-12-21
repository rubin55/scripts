#!/usr/bin/env bash

# Default steam path.
STEAM="$HOME/.local/share/Steam"

# Default proton used.
PROTON="$HOME/Steam/steamapps/common/Proton - Experimental/proton"

# Usage helper.
function error() {
  local MSG=$1
  local EC=$2
  echo "$MSG" 1>&2
  exit $EC
}

# Options loop and case.
while getopts ":s:p:i:" OPTS; do
  case $OPTS in
    s)
    STEAM=$OPTARG
    ;;
    p)
    PROTON=$OPTARG
    ;;
    i)
    ID=$OPTARG
    ;;
    *)
    error "Usage: $0 [-s <steam_path>] [-p <proton_binary>] -i <game_id> command args" 1
    ;;
  esac
done

# Reset argument array.
shift $((OPTIND-1))

# Make sure STEAM, PROTON and ID are set.
[[ -n $STEAM ]] || error "Error: Steam path not specified, exiting" 2
[[ -n $PROTON ]] || error "Error: Proton binary not specified, exiting" 3
[[ -n $ID ]] || error "Error: App/Game id not specified, exiting" 4

# Check if ID is valid.
[[ -d $STEAM/steamapps/compatdata/$ID ]] || error "Error: App/Game id '$ID' does not exist locally" 5

# Make sure we have something to run.
[[ -n $@ ]] || error "Error: No command to run specified, exiting" 6

export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM/steamapps/compatdata/$ID"
export STEAM_COMPAT_DATA_PATH="$STEAM/steamapps/compatdata/$ID"

echo "STEAM=$STEAM"
echo "PROTON=$PROTON"
echo "STEAM_COMPAT_DATA_PATH=$STEAM_COMPAT_DATA_PATH"
echo "STEAM_COMPAT_CLIENT_INSTALL_PATH=$STEAM_COMPAT_CLIENT_INSTALL_PATH"
sleep 2
"$PROTON" run "$@"

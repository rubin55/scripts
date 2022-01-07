#!/usr/bin/env bash

set -e

# Set platform, for WSL set platform to 'windows'. instead of 'linux'.
# Common values: darwin, bsd, gnu/linux, linux, unix, windows.
platform() {
    if [[ "$(uname -r)" =~ "Microsoft" ]]; then
        echo "windows"
    else
        uname -s | tr '[:upper:]' '[:lower:]'
    fi
}

# If route or ip route return 0, we know there is no *other* network
# configured to handle access, because $1 is then handled by the default
# gateway. If it returns anything else we assume we're connected.
# Returns true, false or unknown.
connected() {
    case "$(platform)" in
        darwin)
        if route get "$1" | grep -qw 'destination: default'; then false; else true; fi
        ;;

        bsd|gnu/linux|linux|unix)
        local default=$(netstat -rn | awk '/^0[.]0[.]0[.]0/ {print $2}')
        if ip route get "$1" | grep -qw "$default"; then false; else true; fi
        ;;

        *)
        false
    esac
}

# Get array of directories and all parents.
getdirs () {
    local cd="$1"
    declare -a result

    # Add initial path element.
    result+=("$cd")

    # Iterate over all parents.
    IFS='/' read -r -a path_array <<< "$cd"
    local counter=$((${#path_array[@]} - 1))
    while (( $counter != 0 )); do
        substract=${path_array[$counter]}/$substract
        result+=("${cd::${#cd}-${#substract}}")
        counter=$((counter-1))
    done

    # Add final root path element.
    result+=('/')

    echo "${result[@]}"
}

# Determine if we have a .pgorc file. $HOME/.pgorc is default.
PGO_CONFIG="$HOME/.pgorc"
for config in $(getdirs "$(pwd)"); do
    if [[ -s "${config}/.pgorc" ]]; then
        PGO_CONFIG="${config}/.pgorc"
        break
    fi
done

# Use $PGO_CONFIG if available and set PGO_TARGET_CLUSTER to CONTEXT (using default if not set).
if [[ -s "$PGO_CONFIG" ]]; then

    # Enable allexport, export all key=vals, disable allexport.
    set -a
    source "$PGO_CONFIG"
    set +a
fi

# If in CI, override PGO_TARGET_CLUSTER with CI_ENVIRONMENT_NAME.
if [[ -n $CI_ENVIRONMENT_NAME ]]; then
    export PGO_TARGET_CLUSTER="$CI_ENVIRONMENT_NAME"
else
    # Do some context magic for kubectl.
    if [[ -z $CONTEXT ]]; then
        CONTEXT="$(kubectl config get-contexts | grep '^*' | awk '{print $3}')"
    fi

    # Set PGO_TARGET_CLUSTER to a looked-up value, or directly to CONTEXT.
    case "$CONTEXT" in
    lpc-equinix-ap1)
        export PGO_TARGET_CLUSTER="lpc-ap1"
        ;;
    lpc-equinix-ap2)
        export PGO_TARGET_CLUSTER="lpc-ap2"
        ;;
    lpc-equinix-ot1)
        export PGO_TARGET_CLUSTER="lpc-ot1"
        ;;
    lpc-equinix-ot2)
        export PGO_TARGET_CLUSTER="lpc-ot2"
        ;;
    *)
        export PGO_TARGET_CLUSTER="$CONTEXT"
        ;;
    esac
fi

# Check if PGO_CIDR, PGO_INSTANCE, PGO_K8S_DOMAIN, PGO_SECRET_NAME are set, exit if not.
if [[ -z $PGO_K8S_DOMAIN || -z $PGO_INSTANCE ]]; then
  echo "Error: One or more variables are undefined:"
  [[ ! -z "$PGO_CIDR" ]] &&  echo "  * PGO_CIDR=$PGO_CIDR"
  echo "  * PGO_INSTANCE=$PGO_INSTANCE"
  echo "  * PGO_K8S_DOMAIN=$PGO_K8S_DOMAIN"
  [[ ! -z "$PGO_SECRET_NAME" ]] &&  echo "  * PGO_SECRET_NAME=$PGO_SECRET_NAME"
  echo ""
  echo "You can either set them in ~/.pgorc or simply use environment variables. Exiting..."
  exit 1
fi

# Check for PGO_SECRET_NAME or default to pgo-user-admin
[[ -z $PGO_SECRET_NAME ]] && PGO_SECRET_NAME='pgo-user-admin'

# Connection check if PGO_CIDR is set.
if [[ ! -z $PGO_CIDR ]] && ! connected "$PGO_CIDR"; then
    echo "Target network $PGO_CIDR not available, can't reach operator, aborting.."
    exit 1
fi

# Set-up API server URL.
PGO_APISERVER_URL="https://${PGO_INSTANCE}.${PGO_TARGET_CLUSTER}.${PGO_K8S_DOMAIN}"

# A preference needed for pgo
DISABLE_TLS="true"

# Export PGO_APISERVER_URL, DISABLE_TLS to environment.
export PGO_APISERVER_URL DISABLE_TLS

# Use NAMESPACE environment variable if set, else attempt to extract from arguments.
[[ -z $NAMESPACE ]] && NAMESPACE="$(grep -oEe ' -n [^ ]+' <<< " $@" | sed 's/ -n //')"
if [[ ! -z $NAMESPACE ]]; then

    # Fetch username and password from admin namespace.
    PGOUSERNAME="$(kubectl get secret -n ${NAMESPACE} ${PGO_SECRET_NAME} -o jsonpath='{.data.username}' | base64 --decode)"
    PGOUSERPASS="$(kubectl get secret -n ${NAMESPACE} ${PGO_SECRET_NAME} -o jsonpath='{.data.password}' | base64 --decode)"

    #PGOUSER="$HOME/.pgouser"
    #echo "$PGOUSERNAME:$PGOUSERPASS" > "$PGOUSER"

    # Export PGOUSERNAME, PGOUSERPASS to environment.
    export PGOUSERNAME PGOUSERPASS
fi

# If -n was not specified, but NAMESPACE was set, add -n to resulting arguments.
[[ ! " $@" =~ ' -n ' && ! -z $NAMESPACE ]] && exec pgo --apiserver-url "$PGO_APISERVER_URL" "$@" -n "$NAMESPACE" || exec pgo --apiserver-url "$PGO_APISERVER_URL" "$@"

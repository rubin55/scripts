#!/bin/bash

function getDirs () {
    local cd="$1"
    declare -a result

    # Add initial path element.
    result+=("$cd")

    # Iterate over all parents.
    IFS='/' read -r -a path_array <<< "$cd"
    local counter=$((${#path_array[@]} - 1))
    while [ $counter != 0 ]; do
        substract=${path_array[$counter]}/$substract
        result+=("${cd::${#cd}-${#substract}}")
        counter=$((counter-1))
    done

    # Add final root path element.
    result+=('/')

    echo "${result[@]}"
}

if [ "$1" ]; then
    getDirs "$1"
else
    getDirs "$(pwd)"
fi

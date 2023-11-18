#!/usr/bin/env bash

dir_to_work_on="$1"
old_origin_root="${2%/}"
new_origin_root="${3%/}"

error() {
    local msg=$1
    local nr=$2

    red='\033[0;31m'
    end='\033[0m'

    >&2 printf "${red}$msg${end}\n"
    exit $nr
}

if [ ! -d "$dir_to_work_on" ]; then
    error "Please specify a directory to work on!" 1
fi

if [ -z "$old_origin_root" ]; then
    error "Please specify a new origin root!" 2
fi
if [ -z "$new_origin_root" ]; then
    error "Please specify a new origin root!" 3
fi

echo "Checking '$dir_to_work_on' recursively for git repositories."
echo "Will rewrite any origin which matches old origin root to new origin" 
echo "root. You have 10 seconds to change your mind.."
echo ""
echo "  * Working directory:     '$dir_to_work_on'"
echo "  * Old origin root:       '$old_origin_root'"
echo "  * New origin root:       '$new_origin_root'"
echo ""
sleep 10


for i in `find "$dir_to_work_on" -type d -name .git`; do 
    cd "$i/.."
    old_origin="$(git remote get-url origin)"
    if [[ $old_origin =~ $old_origin_root ]]; then
        echo "Remove old origin: $old_origin"
        git remote remove origin
        
        new_origin="$(echo "$old_origin" | sed "s|$old_origin_root|$new_origin_root|g")"
        echo "Adding new origin: '$new_origin'"    
        git remote add origin "$new_origin"

        echo ""
    fi
    cd - > /dev/null 2>&1
done

#!/usr/bin/env bash

dir="$1"

error() {
    local msg=$1
    local nr=$2

    red='\033[0;31m'
    end='\033[0m'

    >&2 printf "${red}$msg${end}\n"
    exit $nr
}

if [ ! -d "$dir" ]; then
    error "Please specify a directory to fsck." 1
fi

echo "Checking \"$dir\" recursively for git repositories."
echo "Will execute git fsck, git checkout -- ., git reset --hard HEAD, git clean -fdx and git gc:"
echo "Waiting 10 seconds before commencing.. press [CTRL-C] to cancel.."
echo ""
sleep 10


for i in `find "$dir" -type d -name .git`; do 
	echo "Working on $i:"
	cd "$i/.."
	git reflog expire --stale-fix --all
	test $? -eq 0 || error "git reflog expire failed with exit code $?" $?
	git fsck --full
	test $? -eq 0 || error "git fsck failed with exit code $?" $?
	git checkout -- .
	test $? -eq 0 || error "git checkout failed with exit code $?" $?
	git reset --hard HEAD
	test $? -eq 0 || error "git reset failed with exit code $?" $?
	git clean -fdx
	test $? -eq 0 || error "git clean failed with exit code $?" $?
	git gc
	test $? -eq 0 || error "git gc failed with exit code $?" $?
	cd - 2> /dev/null
	echo ""
done

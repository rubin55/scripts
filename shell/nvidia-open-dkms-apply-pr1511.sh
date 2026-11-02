#!/usr/bin/env bash

# Apply NVIDIA open-gpu-kernel-modules PR 1511 to the DKMS sources.
# A pacman hook runs this before 70-dkms-install.hook builds them.
# It reads hook targets (usr/src/nvidia-*/dkms.conf) from stdin.

url="https://github.com/NVIDIA/open-gpu-kernel-modules/pull/1511.diff"

diff=$(mktemp) || exit 1
trap 'rm -f "$diff"' EXIT

if ! curl -fsSL -m 60 "$url" -o "$diff"; then
    echo "warning: cannot fetch $url, sources stay unpatched" >&2
    exit 0
fi

apply() {
    patch -d "$1" -p1 -fs --no-backup-if-mismatch "${@:2}" < "$diff"
}

while read -r target; do
    dir="/${target%/dkms.conf}"
    if apply "$dir" -R --dry-run > /dev/null; then
        echo "$dir: PR 1511 is already applied"
    elif apply "$dir" -N --dry-run > /dev/null && apply "$dir" -N; then
        echo "$dir: applied PR 1511"
    else
        echo "warning: PR 1511 does not apply to $dir, sources stay unpatched" >&2
    fi
done

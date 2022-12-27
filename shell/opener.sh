# A simple wrapper for handling opening directories with a graphical
# browser like explorer or xdg-open.

# Check for input.
if [ -z "$1" ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

# Determine platform.
platform=$(uname -s | tr '[:upper:]' '[:lower:]')
[[ "$(uname -r)" =~ "Microsoft" ]] && platform=windows

if [ "$platform" == "linux" ]; then
    handler="xdg-open"
    input="$1"
fi

if [ "$platform" == "darwin" ]; then
    handler="/usr/bin/open"
    input="$1"
fi

if [ "$platform" == "windows" ]; then
    source ~/Syncthing/Source/Rubin/scripts/shell/winpath.sh
    handler="explorer.exe"
    input="$(winpath "$1" | sed 's|/|\\|g')"
fi



# Execute.
printf '%s\n' "Opening $input"
printf '%s\n' "$handler '$input'" > /tmp/opening.sh
sh /tmp/opening.sh
rm /tmp/opening.sh


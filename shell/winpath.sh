# winpath(<path>)
# Convert path from *nix-style to Windows-style.
# Inspired by Cygwin's cygpath.
#
function winpath {
    typeset input="$1"
    typeset output
    typeset path
    typeset file

    if [ -d "/c/Windows" ]; then
        currentdircmd="cmd.exe /c cd"
    else
        currentdircmd="pwd"
    fi
    
    if [ ! "$input" ]; then
        printf '%s\n' "No input given"
        return 1
    fi

    if [[ "$input" =~ ":" ]] ; then
        # Windows path was passed (ie. contains colon). Only forward slashes.
        output="$(printf '%s\n' "$input" | sed 's|\\|/|g')"
    elif [ -d "$input" ] ; then
        # Path exists locally and is a directory, enter, read out and forward slashes.
        output="$(cd "$input" ; $currentdircmd | sed 's|\\|/|g')"
    elif [ -f "$input" -o "$(dirname "$input")" != "/" ] ; then
        # Path exists locally and is a file, enter parent, read out and forward slashes.
        path="$(cd "$(dirname "$input")" ; $currentdircmd | sed 's|\\|/|g')"
        file="$(basename "$input")"
        output="$path/$file"
    else
        # File does not exist locally, forward slashes.
        output="$(printf '%s\n' "$input" | sed 's|\\|/|g' )"
    fi

    # Check for colon in output, prepend C: if not found.
    if [[ ! "$output" =~ ":" ]];then
        output="$(printf '%s\n' "C:$output")"
    fi

    printf '%s\n' "$output"
    return 0
}

if  [[ "$0" =~ "winpath.sh" ]] ; then
    winpath "$1"
fi


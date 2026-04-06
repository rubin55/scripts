#!/usr/bin/env bash

nvim='/usr/bin/nvim'

# Socket path for the running nvim server.
socket="${XDG_RUNTIME_DIR:-/tmp}/nvim-${USER}.sock"

# Parse flags. -w makes the script wait until all opened files are closed
# in the existing nvim instance (or nvim itself exits).
wait_for_close=0
while [ $# -gt 0 ]; do
    case "$1" in
        -w) wait_for_close=1; shift ;;
        --) shift; break ;;
        -*) echo "Unknown flag: $1" >&2; exit 1 ;;
        *)  break ;;
    esac
done

# Check if nvim is running for the current user with our socket.
if [ -S "$socket" ] && pgrep -u "$USER" nvim > /dev/null 2>&1; then
    # nvim is running.
    if [ $# -eq 0 ]; then
        echo "Neovim is already running. Provide a file to open in the existing instance." >&2
        exit 1
    else
        # Resolve all arguments to absolute paths so the server finds them.
        abs_args=()
        for arg in "$@"; do
            if [ -e "$arg" ] || [[ "$arg" != /* ]]; then
                abs_args+=("$(realpath -m "$arg")")
            else
                abs_args+=("$arg")
            fi
        done
        # Open file(s) in the running nvim.
        "$nvim" --server "$socket" --remote "${abs_args[@]}"

        # Without -w, return immediately after opening the files.
        [ "$wait_for_close" -eq 1 ] || exit 0

        # Neovim has no --remote-wait, so emulate it: install one-shot
        # autocmds in the remote nvim that each append a marker to a signal
        # file when their buffer is closed; wait until the file has one
        # marker per opened file (or until nvim itself exits).
        sigfile=$(mktemp -u --tmpdir "nvim-wait.$$.XXXXXX")
        cmdfile=$(mktemp --suffix=.vim --tmpdir "nvim-wait.$$.XXXXXX")
        trap 'rm -f "$sigfile" "$cmdfile"' EXIT

        # Escape single quotes for embedding in vim single-quoted strings
        # ('' is the escape inside a vim '...' literal).
        sigfile_esc=${sigfile//\'/\'\'}
        # Build a vim list literal of all target file paths.
        targets_vim=""
        for arg in "${abs_args[@]}"; do
            arg_esc=${arg//\'/\'\'}
            [ -n "$targets_vim" ] && targets_vim+=", "
            targets_vim+="'$arg_esc'"
        done

        # Vim script that, for each target, exact-matches its buffer (bufnr()
        # uses pattern matching which can pick up the wrong buffer) and
        # installs a one-shot autocmd that appends a marker to the signal
        # file when the buffer is deleted/wiped. If we can't find the buffer
        # at all, append the marker immediately so the count stays correct.
        cat > "$cmdfile" <<VIMEOF
let s:targets = [$targets_vim]
let s:sigfile = '$sigfile_esc'
for s:target in s:targets
  let s:b = -1
  for s:buf in getbufinfo()
    if s:buf.name ==# s:target
      let s:b = s:buf.bufnr
      break
    endif
  endfor
  if s:b > 0
    execute 'autocmd BufDelete,BufWipeout <buffer=' . s:b . '> ++once call writefile(["."], ''' . s:sigfile . ''', "a")'
  else
    call writefile(['.'], s:sigfile, 'a')
  endif
endfor
VIMEOF

        "$nvim" --server "$socket" --remote-expr "execute('source $cmdfile')" >/dev/null

        # Wait until every opened buffer has been closed, or nvim exits.
        total=${#abs_args[@]}
        while true; do
            count=0
            [ -e "$sigfile" ] && count=$(wc -l < "$sigfile")
            [ "$count" -ge "$total" ] && break
            sleep 0.3
            "$nvim" --server "$socket" --remote-expr "1" >/dev/null 2>&1 || break
        done
    fi
else
    # No nvim running; start a new instance with a known socket.
    exec "$nvim" --listen "$socket" "$@"
fi

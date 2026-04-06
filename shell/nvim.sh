#!/usr/bin/env bash

nvim='/usr/bin/nvim'

# Socket path for the running nvim server.
socket="${XDG_RUNTIME_DIR:-/tmp}/nvim-${USER}.sock"

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

        # Neovim has no --remote-wait, so emulate it: install a one-shot
        # autocmd in the remote nvim that touches a signal file when our
        # buffer is closed, then wait for that file (or for nvim to exit).
        sigfile=$(mktemp -u --tmpdir "nvim-wait.$$.XXXXXX")
        cmdfile=$(mktemp --suffix=.vim --tmpdir "nvim-wait.$$.XXXXXX")
        trap 'rm -f "$sigfile" "$cmdfile"' EXIT

        # Track the first file passed (the "main" one).
        first="${abs_args[0]}"
        # Escape single quotes for embedding in vim single-quoted strings
        # ('' is the escape inside a vim '...' literal).
        first_esc=${first//\'/\'\'}
        sigfile_esc=${sigfile//\'/\'\'}

        # Vim script that resolves the buffer for our file (using getbufinfo
        # to do an exact name match — bufnr() does pattern matching which
        # can pick up the wrong buffer) and installs a one-shot autocmd that
        # touches the signal file when the buffer is deleted/wiped. If the
        # buffer can't be found, signal immediately so we don't hang.
        cat > "$cmdfile" <<VIMEOF
let s:target = '$first_esc'
let s:b = -1
for s:buf in getbufinfo()
  if s:buf.name ==# s:target
    let s:b = s:buf.bufnr
    break
  endif
endfor
if s:b > 0
  execute 'autocmd BufDelete,BufWipeout <buffer=' . s:b . '> ++once call writefile([], ''$sigfile_esc'')'
else
  call writefile([], '$sigfile_esc')
endif
VIMEOF

        "$nvim" --server "$socket" --remote-expr "execute('source $cmdfile')" >/dev/null

        # Wait until the buffer is closed (autocmd touches sigfile) or nvim exits.
        while [ ! -e "$sigfile" ]; do
            sleep 0.3
            "$nvim" --server "$socket" --remote-expr "1" >/dev/null 2>&1 || break
        done
    fi
else
    # No nvim running; start a new instance with a known socket.
    exec "$nvim" --listen "$socket" "$@"
fi

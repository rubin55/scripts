#!/usr/bin/env python3
import os
from configparser import ConfigParser
from subprocess import Popen, PIPE, DEVNULL
from sys import argv, platform, stderr, stdout


# Usage: tipi <key> <user>.
# Note:  the <user> argument is optional.
# Note:  with no <key> or <user> arguments, lists known keys and users.
# Note:  you can also make a link with name <key>-<user>.py to $baseName.
#
# File format .tipi.ini:
#
#  ; .tipi.ini
#  ;
#  ; format: key=path
#  ; Keys are anything you want under the file section.
#  ; the value should be a path to a tab-separated file.
#  ; tsv format: <key> <whitespace> <user> <whitespace> <pass>
#  ;
#  ;
#  [files]
#  ; <key>=<path>/<file>.tsv
#
# File format <file>.tsv
#
#  <key> <whitespace> <user> <whitespace> <pass>
#
# Lines starting with hash <#> are comment lines.

# Note: when a softlink is created to tipi.py and the name of the
# script has te structure of "tipi<sep><key><sep><user>.py" then
# the name wil be expanded to be used as input. For example:
#
#    ln -s tipi.py tipi_com.google_joedoe.py
#
# Invokes tipi.py like:
#
#    tipi.py com.google joedoe
#


# Print shortcut name error.
def print_string_format_error(string):
    print(f'Error: name of script "{string}" has incorrect structure.', file=stderr)
    print(f'       It should be: "tipi<sep><key><sep><user>.py"', file=stderr)
    print(f'       For example:  "tipi_com.google_johndoe.py"', file=stderr)
    pass


# Get key from script name.
def get_key_from_string(string):
    string_sep = string[4]
    key_and_user = string.split(string_sep, 1)[1]
    key = key_and_user.split(string_sep, 1)[0]
    if key:
        return key
    else:
        print_string_format_error(string)
        exit(1)


# Get user from script name.
def get_user_from_string(string):
    script_name_sep = string[4]
    key_and_user = string.split(script_name_sep, 1)[1]
    user = key_and_user.split(script_name_sep, 1)[1]
    if user:
        return user
    else:
        print_string_format_error(string)
        exit(1)


# Magically decide to output to clipboard or stdout.
def output_helper(key, user, passwd):
    clipboard = None

    if stdout.isatty():
        if platform == 'linux' and which('xclip'):
            clipboard = [which('xclip'), '-in', '-selection', 'clipboard']
        elif platform == 'linux' and which('clip'):
            clipboard = [which('clip')]
        elif platform == 'darwin' and which('pbcopy'):
            clipboard = [which('pbcopy'), '-Prefer', 'txt']
        elif platform == 'win32' and which('clip'):
            clipboard = [which('clip')]

    if clipboard:
        out_process = Popen(clipboard, stdout=DEVNULL, stdin=PIPE, stderr=DEVNULL)
        out_result = out_process.communicate(input=bytes(passwd, 'utf-8'))[0]
        print(f'Password for user "{user}" on "{key}" placed in copy-paste buffer.', file=stderr)
    else:
        print(passwd)


# Is something executable?
def is_exe(fpath):
    return os.path.isfile(fpath) and os.access(fpath, os.X_OK)


# Reimplemented which because shutil.which does not work with WSL.
def which(program):
    fpath, fname = os.path.split(program)

    if platform == 'win32':
        suffixes = {'.bat', '.cmd', '.exe', '.py'}
    else:
        suffixes = {'.exe', '.py', '.sh'}

    if fpath:
        # First try without suffix.
        if is_exe(program):
            return program

        # Mm, let's attach our suffixes and
        # return the first that matches.
        for s in suffixes:
            if is_exe(program + s):
                return program + s

    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, program)

            # First try without suffix.
            if is_exe(exe_file):
                return exe_file

            # Mm, let's attach our suffixes and
            # return the first that matches.
            for s in suffixes:
                exe_file = os.path.join(path, program + s)

                if is_exe(exe_file):
                    return exe_file

    return None


# Set script_name and default match_key and match_user.
script_name = os.path.splitext(os.path.basename(argv[0]))[0]
match_key = None
match_user = None

# Check if we're run directly or through link.
if script_name == "tipi":
    if len(argv) == 1:
        pass
    elif len(argv) == 2:
        match_key = argv[1]
    elif len(argv) == 3:
        match_key = argv[1]
        match_user = argv[2]
    else:
        print(f'Error: invalid number of arguments passed: {len(argv)}', file=stderr)
        exit(2)
else:
    match_key = get_key_from_string(script_name)
    match_user = get_user_from_string(script_name)

# Check if ~/.tipi.ini exists.
ini = os.path.expanduser("~") + os.sep + '.tipi.ini'
conf = ConfigParser()
if os.path.isfile(ini):
    conf.read(ini)
else:
    print(f'Error: file "{ini}" not found or not readable', file=stderr)
    exit(3)

# Make sure we have gpg.
gpg = which("gpg")
if not gpg:
    print(f'Error: "gpg" executable not found on path', file=stderr)
    exit(4)

# Read gpg files into array.
gpg_files = [kv[1] for kv in conf.items("files")]

# Command used for gpg.
gpg_command = ['gpg', '--batch', '--quiet', '--decrypt']

# Loop over array, find stuff.
for gpg_file in gpg_files:
    gpg_process = Popen(gpg_command + [gpg_file], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    for line_number, line in enumerate(gpg_process.stdout):
        if line.rstrip() and not line.startswith(b'#'):

            try:
                k, u, p = line.decode().split()  # or .split('\t')

                if not match_key and not match_user:
                    print(f'{k}\t{u}')
                elif match_key in k and not match_user:
                    output_helper(k, u, p)
                    exit(0)
                elif match_key in k and match_user in u:
                    output_helper(k, u, p)
                    exit(0)

            except ValueError:
                pass
                # print(f'Warning: white-space error: {gpg_file}:{line_number + 1}', file=stderr)

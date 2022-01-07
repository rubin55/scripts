hooks
=====

For our branching strategy we made a few agreements. These can be found in the
Structure repository in [CONTRIBUTING.md](https://gitlab.com/raaftech/structure/blob/issue/20/CONTRIBUTING.md).
A few of these rules are about commits, and how they should be formatted. This
repository contains some Git hooks that will enforce a few of these agreements:

* Commit subject should be properly formatted
* The length of the subject should be short
* Check if the branch name is good
* Does the referenced ticket exist

Because Gitlab.com doesn't allow for custom hooks, we need to do these checks
client-side. This means everyone has to install these hooks in their Structure
repository. I put in some effort to make this installation as easy as possible.

requirements
------------

* python3
* python-requests
* this repository, and the Structure repo on the same filesystem (for symlinks)
* an [API token](https://gitlab.com/profile/personal_access_tokens)

installation
------------

This repository contains an install script named `commit-install.py`, which can be run
interactively and non-interactively, depending on the arguments given.

**Important:**<br>
Make sure your CWD is the same as the `commit-install.py` script as the script will NOT
work when run from another location!

**Windows users:**<br>
Run the installation script with Administrator privileges. Installation creates
symlinks, and creating symlinks needs admin rights :)

Running the script without any arguments:

```
# ./commit-install.py
The path to the repository you want to install the hooks to:
~/tmp/test
The API endpoint to use [https://gitlab.com/api/v3/]:

The API token to use:
x-Jd86hjUxP42MVHXiUQ
The project ID of the repository on Gitlab:
912466

Writing the config file to /home/boy/tmp/test/.git/hooks/gitlab.conf
Creating symlinks to our hooks.
Symlinking /home/boy/checkout/raaf/hooks/commit-message.py to /home/boy/tmp/test/.git/hooks/commit-msg
```

Options can also be specified on the command-line, see `./commit-install.py -h`. Any
option that isn't specified on the command-line will be asked for interactively.
Note that in the example below we give argument `u` an empty string so the
default endpoint will be used.

```
# ./commit-install.py -r ~/tmp/test -u '' -t x-Jd9ikabcde2MVHXiUQ -p 912466

Writing the config file to /home/boy/tmp/test/.git/hooks/gitlab.conf
Creating symlinks to our hooks.
Symlinking /home/boy/checkout/raaf/hooks/commit-message.py to /home/boy/tmp/test/.git/hooks/commit-msg
```

The install script will validate all the arguments before writing any files to
disk.

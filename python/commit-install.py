#!/usr/bin/env python

import argparse
import configparser
import os
import sys
import urllib.parse

helper = __import__("commit-helper")

DEFAULT_API_ENDPOINT = "https://gitlab.com/api/v3/"
HOOKS = {"commit-msg": "commit-message.py"}

parser = argparse.ArgumentParser(description="Install our git hooks"
                                 " to a repository. Any missing options"
                                 " will be asked for interactively.")
parser.add_argument("-r", "--repository", help="The destination"
                    " repository for our hooks")
parser.add_argument("-u", "--url", help="The API endpoint")
parser.add_argument("-t", "--token", help="Your API token")
parser.add_argument("-p", "--project", help="The project ID of the repository"
                    " on Gitlab")
args = vars(parser.parse_args())

# get the arguments from the namespace returned by parse_args
repository = args["repository"]
url = args["url"]
token = args["token"]
project = args["project"]

# did we get a repository as argument? if not, ask for it interactively
if repository is None:
    repository = input("The path to the repository you want to install "
                       "the hooks to:\n")
    repository = os.path.expanduser(repository)
# check if the repository actually is a git repository
helper.isdir(repository)
helper.isdir(os.path.join(repository, ".git{}hooks".format(os.path.sep)))

# did we get an url as argument?
# if yes, but it was empty, set it to the default
if url is not None and len(url) == 0:
    url = DEFAULT_API_ENDPOINT
# if not, ask for it interactively. if the user presses enter immediately
# use the default endpoint
if url is None:
    url = input("The API endpoint to use [{}]:\n".format(DEFAULT_API_ENDPOINT))
    if len(url) == 0:
        url = DEFAULT_API_ENDPOINT
    if url[-1] != "/":
        url += "/"
# check if the url is valid and https is used
parsedurl = urllib.parse.urlparse(url)
if parsedurl.scheme == "" or parsedurl.netloc == "":
    helper.die("Invalid URL used as endpoint.")
if parsedurl.scheme != "https":
    helper.die("HTTPS endpoints only, please.")

# did we get a token as argument? if not, ask for it interactively
if token is None:
    token = input("The API token to use:\n")
# is the token valid?
r = helper.get_gitlab_url(token, "{}users".format(url), False)
if r.status_code == 401:
    helper.die("Invalid API token used")
r.raise_for_status()

# did we get a project as argument? if not, ask for it interactively
if project is None:
    project = input("The project ID of the repository on Gitlab:\n")
# check if the project exists
r = helper.get_gitlab_url(token, "{}projects/{}".format(url, project), False)
if r.status_code == 404:
    helper.die("Project doesn't exist")

print()

# everything is OK, proceed to write the config file
config = configparser.ConfigParser()
config["gitlab"] = {}
config["gitlab"]["projectid"] = project
config["gitlab"]["url"] = url
config["gitlab"]["token"] = token

config_file = os.path.join(repository,
                           ".git{0}hooks{0}gitlab.conf".format(os.path.sep))
print("Writing the config file to {}".format(config_file))
with os.fdopen(os.open(config_file,
                       os.O_WRONLY | os.O_CREAT, 0o600), 'w') as handle:
    config.write(handle)

if sys.platform == "win32":
    print("Running on windows, symlinking helper.py as well.")
    src = os.path.join(os.getcwd(), "commit-helper.py")
    dst = os.path.join(repository, ".git{}hooks/commit-helper.py".format(os.path.sep))
    if not os.path.isfile(dst):
        os.symlink(src, dst)
    else:
        print("{} already exists. skipping.".format(dst))

print("Creating symlinks to our hooks.")
for hook, hookfile in HOOKS.items():
    src = os.path.join(os.getcwd(), hookfile)
    dst = os.path.join(repository, ".git{0}hooks/{1}".format(os.path.sep,
                                                             hook))

    print("Symlinking {} to {}".format(src, dst))
    if not os.path.isfile(dst):
        os.symlink(src, dst)
    else:
        print("{} already exists. Skipping.".format(dst))

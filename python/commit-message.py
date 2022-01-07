#!/usr/bin/env python

import configparser
import os
import sys
import re

helper = __import__("commit-helper")

COMMIT_BASE_PATTERN = "[A-Z][\w\d'\" -,.]+[\w'\"\)\]\}`]"
COMMIT_ISSUE_SUBJECT_PATTERN = "^{}$".format(COMMIT_BASE_PATTERN)
COMMIT_MASTER_SUBJECT_PATTERN = "^#([0-9]+): {}$".format(COMMIT_BASE_PATTERN)

commit_msg_file = sys.argv[1]

# parse config
try:
    config = configparser.ConfigParser()
    config.read(".git/hooks/gitlab.conf")
    GITLAB_PROJECT_ID = config.get("gitlab", "projectid")
    GITLAB_API_URL = config.get("gitlab", "url")
    GITLAB_API_TOKEN = config.get("gitlab", "token")
except configparser.NoSectionError:
    helper.die("Error while reading/parsing .git/hooks/gitlab.conf")

git = helper.Git(GITLAB_API_URL, GITLAB_API_TOKEN, GITLAB_PROJECT_ID)
branch = git.get_branch(os.getcwd())
with open(commit_msg_file, "r") as f:
    commit_subject = f.readline()

if branch == "master":
    git.check_commit_subject(COMMIT_MASTER_SUBJECT_PATTERN, commit_subject,
                             diemessage="Commit subject is not of proper form."
                             " An example: \"#ID: Subject\".\nExact regex to "
                             "match: "
                             "\"{}\"".format(COMMIT_MASTER_SUBJECT_PATTERN))
    issue_id = re.match(COMMIT_MASTER_SUBJECT_PATTERN,
                        commit_subject).group(1)
    git.check_commit_issue(issue_id)
else:
    capture_issue_id = re.search("^issue/(\d+)$", branch)
    if capture_issue_id:
        issue_id = capture_issue_id.group(1)
        git.check_commit_subject(COMMIT_ISSUE_SUBJECT_PATTERN, commit_subject,
                                 "Commit subject is not of proper form. "
                                 "An example: \"Subject\" (so without an "
                                 "\"#ID:\"-prefix)\n"
                                 "Exact regex to match: \""
                                 "{}\"".format(COMMIT_ISSUE_SUBJECT_PATTERN))
        git.check_commit_issue(issue_id)
    else:
        helper.die("Unsupported branch, either use master or an issue"
                   " branch.")

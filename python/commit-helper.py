import os
import subprocess
import sys
import requests
import re


def die(deathcry):
    print(deathcry)
    sys.exit(1)


def isdir(dir):
    if not (os.path.exists(dir)):
        die("Path {} doesn't exist".format(dir))
    if not (os.path.isdir(dir)):
        die("{} is not a directory.".format(dir))


# do a get on the gitlab api, building the proper header
# set checkcode to False if you don't want to raise an exception
# on "bad" status codes
def get_gitlab_url(token, url, checkcode=True):
    headers = {"PRIVATE-TOKEN": token}
    r = requests.get(url, headers=headers)
    if checkcode:
        r.raise_for_status()
    return r


class Git:
    def __init__(self, api_endpoint, api_token, projectid):
        self.api_endpoint = api_endpoint
        self.api_token = api_token
        self.projectid = projectid
        self.project_exists()

    # check if a project with the configured ID exists
    def project_exists(self):
        url = "{}projects/{}".format(self.api_endpoint, self.projectid)
        r = get_gitlab_url(self.api_token, url, False)
        if r.status_code == 404:
            die("Project with id \"{}\" doesn't exist.".format(self.projectid))

    # check_commit_subject checks the commit's subject against RAAF conventions
    def check_commit_subject(self, pattern, subject, diemessage=None):
        if not re.match(pattern, subject):
            if diemessage is None:
                die("Commit isn't of proper form "
                    " (exact regex to match: \"{}\".".format(pattern))
            else:
                die(diemessage)
        if len(subject) > 100:
            die("Please use a shorter commit subject, ideally max 50.")

    # check_commit_issue uses Gitlab's API to check if the used issue ID
    # exists, and the issue has the opened or reopened status
    def check_commit_issue(self, iid):
        url = "{}projects/{}/issues?iid={}".format(self.api_endpoint,
                                                   self.projectid, iid)
        r = get_gitlab_url(self.api_token, url)
        if len(r.json()) == 1:
            json = r.json()[0]
            if not (json["state"] == "opened" or json["state"] == "reopened"):
                die("Issue #{} should be open, but is {}, cannot commit on "
                    "unopened ticket.".format(iid, json["state"]))
        else:
            die("Issue #{} doesn't exist, cannot commit.".format(iid))

    # check if a directory is a git repository, if so, return the current
    # branch
    def get_branch(self, dir):
        isdir(dir)
        git_dir = os.path.join(dir, ".git")
        isdir(git_dir)
        proc = subprocess.Popen(["git", "symbolic-ref", "HEAD"],
                                stdout=subprocess.PIPE)
        pout = proc.communicate()[0]
        return re.search("^refs/heads/(.*)$", pout.decode('utf-8')).group(1)

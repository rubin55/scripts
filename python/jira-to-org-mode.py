#!/usr/bin/env python3
import os
from configparser import ConfigParser
from sys import stderr

from jira import JIRA

# Example ~/.jira.ini
# [jira]
# instance = https://jira.example.com/jira
# token = sometoken
# query = project = FBS AND issuetype not in (Epic, Sub-task) AND status in (Open, "In Progress") ORDER BY key ASC
#
# Check if ~/.jira.ini exists.
inifile = os.path.expanduser("~") + os.sep + '.jira.ini'
config = ConfigParser()
if os.path.isfile(inifile):
    config.read(inifile)
else:
    print(f'Error: file "{inifile}" not found or not readable', file=stderr)
    exit(3)

# Jira connection object.
jira = JIRA(config['jira']['instance'], token_auth=(config['jira']['token']), validate=True)

# Issue list.
issues = jira.search_issues(config['jira']['query'], maxResults=1000, fields=['status', 'summary'])

if len(issues) > 0:
    # Print an org-mode formatted header.
    print('#+title: ICTU Todo')

for issue in issues:
    # Status.
    status = 'TODO'
    if issue.fields.status.name == 'Closed':
        status = 'DONE'

    # Summary.
    summary = issue.fields.summary

    # Print an org-mode formatted todo line.
    print(f"* {status} {summary} ({issue})")

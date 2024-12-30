#!/bin/sh

alias tracker=localsearch

echo "Disabling all non-recursive directory indexes..."
gsettings set org.freedesktop.Tracker3.Miner.Files index-single-directories '[]'

echo "Enabling recursive directory indexing for: Documents, Music, Pictures, Library..."
gsettings set org.freedesktop.Tracker3.Miner.Files index-recursive-directories "['&DOCUMENTS', '&MUSIC', '&PICTURES', '/home/rubin/Library']"

echo "Disabling indexing within directories: po, CVS, core-dumps, lost+found, .git, .hg, .svn, .venv, build, target, node_modules..."
gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories "['po', 'CVS', 'core-dumps', 'lost+found', '.git', '.hg', '.svn', '.venv', 'build', 'target', 'node_modules']"

echo "Disabling indexing of any directories containing files: .trackerignore, .nomedia"
gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories-with-content "['.trackerignore', '.nomedia']"

echo ""

echo "Currently enabled tracker settings:"
gsettings list-recursively org.freedesktop.Tracker3.Miner.Files

echo ""

echo "Currently enabled tracker indexes:"
tracker index

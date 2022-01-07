#!/usr/bin/python

import argparse
import os
import random
import subprocess

version='\nsetcolor version 0.1\n'

schemes = os.environ['USERPROFILE'].replace('\\', '/') + '/Syncthing/Source/Other/iterm2-color-schemes/schemes'

parser = argparse.ArgumentParser(description='Set terminal colors and save them, with random support.')
parser.add_argument('-l', '--list',    action='store_true', help='list available themes')
parser.add_argument('-n', '--name',    action='store',      help='select a specific theme by name')
parser.add_argument('-r', '--random',     action='store_true',      help='select a random theme')
parser.add_argument('-v', '--version', action='version',    version=version)

args = parser.parse_args()

if args.list:
    names = [n.replace('.itermcolors', '') for n in os.listdir(schemes)]
    print(names)
    exit

if args.name:
    command = ['colortool', '-b', schemes + '/' + args.name + '.itermcolors']
    subprocess.call(command, shell=True)
    exit

if args.random:
    command = ['colortool', '-b', schemes + '/' + random.choice(os.listdir(schemes))]
    subprocess.call(command, shell=True)
    exit
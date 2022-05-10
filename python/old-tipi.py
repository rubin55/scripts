#!/usr/bin/env python3

# Load modules
from argparse import ArgumentParser
from configparser import ConfigParser
from os.path import expanduser,isfile,sep
from shlex import quote
from subprocess import Popen, PIPE
from sys import argv,exit,stderr

import os

# Version.
version=\
"""
Tipi version 0.4
"""

# Load hsync configuration.
ini = expanduser("~") + sep + '.tipi.ini'
conf = ConfigParser()
if isfile(ini):
    conf.read(ini)
else:
    print('Error: cannot find configuration file')
    print('Expected to find ' + ini)

# Create an argument parser object.
parser = ArgumentParser(description='Tipi, a Tiny (but) Intelligent Password Intermediary.')
parser.add_argument('-k', '--key',     action='store',      help='the search key to match with')
parser.add_argument('-u', '--user',    action='store',      help='the user or subject to match with')

parser.add_argument('-s', '--show',    action='store_true', help='show entry (no argument matches all)')
parser.add_argument('-c', '--clip',    action='store_true', help='copy password to clipboard')
parser.add_argument('-p', '--print',   action='store_true', help='print password to standard out')
parser.add_argument('-v', '--version', action='version',    version=version)


args = parser.parse_args()

def eprint(*args, **kwargs):
    print(*args, file=stderr, **kwargs)

def createWorkList():
    "Will create a workList."
    workList = []

    for (localKey, localValue) in conf.items("files"):
        workItem = []

        workItem.extend(['gpg', '--batch', '--quiet', '--decrypt'])
        workItem.extend([localValue])

        workList.append(workItem)

    return workList

def createResultList(workList):
    "Will take a worklist and execute it."
    resultList = []

    for work in workList:
        p = Popen(work, stdin=PIPE, stdout=PIPE, stderr=PIPE)

        for lineNumber, line in enumerate(p.stdout):
            if line.rstrip() and not line.startswith(b'#'):
                resultItem = []

                try:
                    k, u, p = line.decode().split('\t')
                except:
                    eprint("Notice: non-well-formed file: {}, line: {}".format(work[-1], lineNumber))

                if args.key and args.key in k:
                    if args.user and args.user in u:
                        resultItem.extend([k, u, p])
                        resultList.append(resultItem)
                    elif not args.user:
                        resultItem.extend([k, u, p])
                        resultList.append(resultItem)


    return resultList


if len(argv) > 1:
    items = createResultList(createWorkList())

    if items:
        for item in items:
            if args.show and args.print:
                info="key=" + item[0] + ", user=" + item[1] + ", pass=" + item[2]
                print(info)
            elif args.show:
                info="key=" + item[0] + ", user=" + item[1] + ", pass=[hidden]"
                print(info)
            elif args.print:
                print(item[2])

            if args.clip:
                if os.name == 'nt':
                    command1="echo " + quote(item[2].strip()) + "| clip"
                    #Popen(command1, shell=True, stdout=PIPE)
                    os.system(command1)

                if os.name == 'posix':
                    command1="echo " + quote(item[2].strip()) + "| xclip -selection primary"
                    command2="echo " + quote(item[2].strip()) + "| xclip -selection clipboard"
                    command3='sleep 10;killall xclip'
                    Popen(command1, shell=True, stdout=PIPE)
                    Popen(command2, shell=True, stdout=PIPE)
                    Popen(command3, shell=True)

        exit(0)

    else:
        exit(1)

else:
    parser.print_help()


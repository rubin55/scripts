#!/usr/bin/env python3

# Load modules
from argparse import ArgumentParser
from configparser import ConfigParser
from os.path import expanduser,isfile,sep
from socket import gethostname
from subprocess import call
from sys import exit

# Version.
version=\
"""
Hsync version 0.1
"""
# Load hsync configuration.
ini = expanduser("~") + sep + '.hsync.ini'
conf = ConfigParser()
if isfile(ini):
    conf.read(ini)
else:
    print('Error: cannot find configuration file')
    print('Expected to find ' + ini)

# Create an argument parser object.
parser = ArgumentParser(description='Hsync, an easy directory synchronisation tool.')

parser.add_argument('command',         action='store',      help='the main command to run', choices=['to','from'])
parser.add_argument('host',            action='store',      help='the host to sync to|from', choices=conf.sections())
parser.add_argument('-a', '--asif',    action='store_true', help='act as if and pretend to do something')
parser.add_argument('-v', '--version', action='version',    version=version)

args = parser.parse_args()

def createWorklist():
    "Will create a worklist, given to|from and a host"
    workList=[]

    if args.host == gethostname():
        print('Error: you cannot sync something to itself')
        print('Specify another host instead of ' + args.host)
        exit(1)

    local=conf.items(gethostname())
    remote=conf.items(args.host)

    for (localKey, localValue) in local:
        directory=localValue.split(',')[0].replace('/', '\\')
        for (remoteKey, remoteValue) in remote:
            share='\\\\' +args.host + '\\' + remoteValue.split(',')[1].replace('/', '\\')
            if localKey == remoteKey:
                workItem=[]

                if args.asif == True:
                    workItem.extend(['echo'])

                workItem.extend(['robocopy', '/mir', '/fft', '/copy:dt'])
                if args.command == 'to':
                    workItem.extend([directory, share])
                elif args.command == 'from':
                    workItem.extend([share, directory])
                else:
                    print('args.command was not to or from.. should be impossible!')
                    exit(1)

                workList.append(workItem)

    return workList


def sync(workList):
    "Will take a worklist and execute it."
    for work in workList:
        call(work,shell=True)

sync(createWorklist())

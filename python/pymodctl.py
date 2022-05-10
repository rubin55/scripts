#!/usr/bin/env python

from sys import exit
from optparse import OptionParser

parser = OptionParser()

parser.add_option("-l", "--list", action="store_true", default=False, help="List installed modules")
parser.add_option("-v", "--version", action="store_true", default=False, help="Show version")

(options, args) = parser.parse_args()

if options.version == False and options.list == True:
    for dist in __import__('pkg_resources').working_set:
        print dist.project_name.replace('Python','')

if options.version == True and options.list == False: 
    print '0.1'


#!/usr/bin/env python

import pyodbc
import csv
import sys

usage="""%s""" % sys.argv[0]

if len(sys.argv) > 1:
    if sys.argv[1] == "-h" or sys.argv[1] == "--help":
        print usage
        sys.exit()

try:
    con = pyodbc.connect('DSN=fake;PWD=fake')
    out = csv.writer(open('files.csv', 'wb'), delimiter=',')
    out.writerow(['filename', 'parentdir', 'allocsize', 'owner'])

    try:
        cursor = con.cursor()
        cursor.execute("""
        SELECT   SRMFILE.FILENAME, SRMFILE.PARENTDIR, SRMFILE.ALLOCSIZE, SRMFILE.OWNER 
        FROM     SRMFILE, SRMFOLDER, SRMFILESYSTEM
        WHERE    SRMFILE.FOLDERKEY=SRMFOLDER.FOLDERKEY 
        AND      SRMFILE.FILESYSTEMKEY=SRMFILESYSTEM.FILESYSTEMKEY 
        AND      SRMFILESYSTEM.FSTYPE = 'NetworkFS'
        """)

        for row in cursor:
            print 'Processing:', repr(row[0])
            out.writerow([row[0], row[1], row[2], row[3]])


    except pyodbc.DatabaseError, e:
        sys.stderr.write("Fatal Error.n")

        if type(e.message) == dict:
            for (k, v) in e.message.iteritems():
                sys.stderr.write("%s: %sn" % (k, v))

        else:
            sys.stderr.write("Error: %sn" % e.message);

        sys.exit()

finally:
    try:
        con.close() 

    except pyodbc.DatabaseError, e:
        pass


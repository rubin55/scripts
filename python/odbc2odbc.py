#!/usr/bin/env python

import pyodbc
import sys

usage="""%s""" % sys.argv[0]

if len(sys.argv) > 1:
    if sys.argv[1] == "-h" or sys.argv[1] == "--help":
        print usage
        sys.exit()

con_source = pyodbc.connect('DSN=fake;PWD=fake')
con_target = pyodbc.connect('DSN=fake;PWD=fake')

cursor_source = con_source.cursor()
cursor_target = con_target.cursor()

cursor_target.execute(""" 
    DROP TABLE USER_FILES
""")

cursor_target.execute("""
    CREATE TABLE USER_FILES(
        filename varchar(1024),
        parentdir varchar(2048),
        allocsize decimal(20),
        ownername varchar(20)
    )
""")

cursor_source.execute("""
    SELECT   SRMFILE.FILENAME, SRMFILE.PARENTDIR, SRMFILE.ALLOCSIZE, SRMFILE.OWNER 
    FROM     SRMFILE, SRMFOLDER, SRMFILESYSTEM
    WHERE    SRMFILE.FOLDERKEY=SRMFOLDER.FOLDERKEY 
    AND      SRMFILE.FILESYSTEMKEY=SRMFILESYSTEM.FILESYSTEMKEY 
    AND      SRMFILESYSTEM.FSTYPE = 'NetworkFS'
""")

for row in cursor_source:
    print 'Processing:', repr(row[0])
    cursor_target.execute("INSERT INTO USER_FILES VALUES(?, ?, ?, ?)", row[0], row[1], row[2], row[3])

con_target.commit()
con_target.close()
con_source.close()


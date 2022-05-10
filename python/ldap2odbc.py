#!/usr/bin/env python

import ldap
import pyodbc
import sys

usage="""%s""" % sys.argv[0]

if len(sys.argv) > 1:
    if sys.argv[1] == "-h" or sys.argv[1] == "--help":
        print usage
        sys.exit()

con_ldap = ldap.initialize("ldap://someldapserver")
con_odbc = pyodbc.connect('DSN=fake;PWD=fake')

result = con_ldap.search_s(
    'o=SOMEORG',
    ldap.SCOPE_SUBTREE,
    '(&(objectClass=person)(netusername=*)(department=*)(companyname=*))',
    ['cn', 'netusername', 'department', 'companyname'])

cursor = con_odbc.cursor()

cursor.execute(""" 
    DROP TABLE USER_ENTRIES
""")

cursor.execute("""
    CREATE TABLE USER_ENTRIES(
        cn varchar(100),
        netusername varchar(20),
        department varchar(20),
        companyname varchar(20)
    )
""")

for dn,entry in result:
    print 'Processing:', repr(dn)
    cursor.execute("INSERT INTO USER_ENTRIES VALUES(?, ?, ?, ?)", entry['cn'][0], entry['netusername'][0], entry['department'][0], entry['companyname'][0])

con_odbc.commit()
con_odbc.close()

con_ldap.unbind()

#!/usr/bin/env python

import ldap
import csv
import sys

usage="""%s""" % sys.argv[0]

if len(sys.argv) > 1:
    if sys.argv[1] == "-h" or sys.argv[1] == "--help":
        print usage
        sys.exit()

try:
    con = ldap.initialize("ldap://someldapserver")
    out = csv.writer(open('users.csv', 'wb'), delimiter=',')
    out.writerow(['cn', 'netusername', 'department', 'companyname'])


    try:
        result = con.search_s('o=SOMEORG',
            ldap.SCOPE_SUBTREE,
            '(&(objectClass=person)(netusername=*)(department=*)(companyname=*))',
            ['cn', 'netusername', 'department', 'companyname'])
        for dn,entry in result:
            print 'Processing:', repr(dn)
            out.writerow([entry['cn'][0], entry['netusername'][0], entry['department'][0], entry['companyname'][0]])

    except ldap.LDAPError, e:
        sys.stderr.write("Fatal Error.n")

        if type(e.message) == dict:
            for (k, v) in e.message.iteritems():
                sys.stderr.write("%s: %sn" % (k, v))

        else:
            sys.stderr.write("Error: %sn" % e.message);

        sys.exit()

finally:
    try:
        con.unbind()

    except ldap.LDAPError, e:
        pass


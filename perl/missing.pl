#!/usr/bin/env perl

# Extract prepared lists of virtual machines within NetBackup and vSphere.
@vsphere_vmlist = qx(listvm.pl);
@netbackup_vmlist = qx(listbu.pl);

# Parse each line and output a short name.
foreach $vm (@vsphere_vmlist) {
    if(grep(/$vm/, @netbackup_vmlist)) {
        print "yes: " . $vm;
    } else {
        print " no: " . $vm;
    }
}


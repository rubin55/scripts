#!/bin/sh

# Fetch our payload.
ftp -n 192.168.250.242 <<EOT
user emc emcemc
bin
get emcgrab_SunOS_v4.2.tar
get emcgrab.main.replace
quit
EOT

# Make sure there's no old emcgrab lying around.
cd /root
rm -rf emcgrab
tar xf emcgrab_SunOS_v4.2.tar

# Make the legaleze disappear.
cd /root/emcgrab
cp ../emcgrab.main.replace emcgrab.main

# Do the emcgrab run.
./emcgrab.sh -autoexec

# Upload the output.
cd outputs
scp * root@192.168.248.40:/root/collect/


#!/usr/bin/expect

################################################################################
# expectMP.sh                                                                  #
#                                                                              #
# Connect to MP of rx2600 system and START, STOP or KILL (if too hot)          #
#                                                                              #
#                                                                              #
#                                                                              #
################################################################################

# useful flag for debugging expect scripts
#exp_internal 1

# make sure timeouts are taken when doing commands
set force_conservative 1

# usage statement
if { $argc<8 } {
        send_user "Usage: $argv0 -h MP_hostname -l MP_logon -p MP_passwd -a MP_action (START|STOP|KILL) \n"
        exit
}

# get commandline options
set root 0
for {set i 0} {$i<$argc} {incr i} {
        set arg [lindex $argv $i]
        switch -- $arg  "-root" {       set root 1
                }       "-h"    {       incr i
                                        set hostname [lindex $argv $i]
                }       "-l"    {       incr i
                                        set username [lindex $argv $i]
                }       "-p"    {       incr i
                                        set password [lindex $argv $i]
                }       "-a"    {       incr i
                                        set action [lindex $argv $i]
                }
}

# do some evil telnet stuff
spawn /usr/bin/telnet mp

# login to the MP
expect "MP login:"
send -- "$username\r"
expect "MP password:"
send -- "$password\r"

# go to command menu (CM)
expect "MP>"
send "CM\r"

# do power control (just say NO)
expect "MP:CM>"
send "PC\r" 
expect -regexp "Enter menu item or ... to Quit:"

# perform the correct power action (ON, G, OFF or Q)
switch -- $action "START" {  
                    # turn box ON
                    send "ON\r"
                    expect -gl "*System will be powered on.*Confirm? *: "
                    send "Y\r"
                } "STOP" { 
                    # turn box off GRACEFULLY (shutdown OS first, then poweroff)
                    send "G\r"
                    expect -gl "*System will be gracefully shutdown.*Confirm? *: "
                    send "Y\r"
                } "KILL" { 
                    # turn box off IMMEDIATELY (warning: may cause broken OS)
                    send "OFF\r"
                    expect -gl "*System will be powered off.*Confirm? *: "
                    send "Y\r"
                } default { 
                    # don't do anything
                    send "Q\r"
                    send_user "Invalid MP_action, valid options are START, STOP and KILL\n"
}

# exit the mp
expect "MP:CM>"
send "MA\r"
expect "MP>"
send "X\r"
## EOF

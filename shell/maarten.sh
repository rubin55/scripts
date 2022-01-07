#!/bin/bash


###############################################################################
# Script to automatically test the deployment by the OpenPCF suite, and       #
# output the results to xml for further use by other tools.                   #
###############################################################################
# Exit codes                                                                  #
# 0 => Well done, son!                                                        #
# 1 => One day, you'll be root, too...                                        #
# 2 => Missing a needed tool, please install.                                 #
# 3 => A necessary operation failed!                                          #
# 4 => We hitted a not-yet-implemented feature, sorry :'(                     #
###############################################################################
# Known issues:                                                               #
#   * Default Ubuntu/Debian tftp-client suxxorz, use tftp-hpa.                #
###############################################################################
# Todo's:                                                                     #
# In test_* functies EERST output opvangen, DAN linecount berekenen (handig   #
# mbt. logging in geval van failure)                                          #
# Logging in geval van failure (nice to have)                                 #
###############################################################################


###############################################################################
# Variables go here.                                                          #
###############################################################################

PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
TSTGRP=${1:-localhost}
SESUSR=${2:-maarten}
LOGDIR=logs
OUTPUTDIR=results
NAME_DATE=`date +%s`
LOGFILE="$LOGDIR/testes.log"
OUTPUTFILE="$OUTPUTDIR/$NAME_DATE.xml"
TESTUSR=testor
TESTPWD=hatsietest

###############################################################################
# Functions go here.                                                          #
###############################################################################

function herald {
    local MESSAGE=$1
    echo "**$MESSAGE"
    echo "`date +%D%t%T` $MESSAGE">>$LOGFILE
}

function make_outfile {
    mkdir -p $OUTPUTDIR
    if [ -L $OUTPUTDIR/output.xml ] ; then
        rm -f $OUTPUTDIR/output.xml
        ln -s $OUTPUTFILE $OUTPUTDIR/output.xml
    else
        ln -s $OUTPUTFILE $OUTPUTDIR/output.xml
    fi

    echo '<?xml version="1.0" encoding="ISO-8859-1"?>' > $OUTPUTFILE
    echo '<?xml-stylesheet type="text/xsl" href="style.xsl"?>' >> $OUTPUTFILE
    echo  >> $OUTPUTFILE
    echo '<data>' >> $OUTPUTFILE
    echo '    <test>' >> $OUTPUTFILE
    echo >> $OUTPUTFILE
    echo "<date>${DATE}</date>" >> $OUTPUTFILE
}

function close_outfile {
    echo '    </test>' >> $OUTPUTFILE
    echo '</data>' >> $OUTPUTFILE
}

function make_logfile {
    mkdir -p $LOGDIR
    touch $LOGFILE
    if [ `cat $LOGFILE|wc -l` -ge 400 ] ; then
        mv -f $LOGFILE "$LOGFILE.1"
    fi
}

function have_root {
    if [ $USER != root ] ; then
        echo "You have to be r00t to do this!"
        exit 1
    fi
}

function have_tool {
    TOOLNAME=$1
    eval "TOOLPATH=`which $TOOLNAME`" # NOTE: have_tool sets $1 as a GLOBAL VARIABLE!
    eval "$TOOLNAME=$TOOLPATH"

    if [ -n "${!TOOLNAME}" -a -x "${!TOOLNAME}" ] ; then
        herald "We have $TOOLNAME, proceeding..."
    else
        herald "We need $TOOLNAME to proceed, exiting!"
        exit 2
    fi
}

function have_dig { have_tool "dig"; }
function have_dhcping { have_tool "dhcping"; }
function have_tftp { have_tool "tftp"; }
function have_ntpdate { have_tool "ntpdate"; }
function have_telnet { have_tool "telnet"; }
function have_wget { have_tool "wget"; }
function have_openssl { have_tool "openssl"; }
function have_smbclient { have_tool "smbclient"; }
function have_session { have_tool "session"; }

function test_smtp {
    local LINECOUNT=`(
        sleep 1
        echo "ehlo takeshi.example.com"
        sleep 1
        echo "mail from:root@example.com"
        sleep 1
        echo "rcpt to:root@example.com"
        sleep 1
        echo "data"
        sleep 1
        echo "subject: testmail"
        sleep 1
        echo " "
        sleep 1
        echo " footest, barbla!"
        sleep 1
        echo "."
    ) | telnet $1 25 2>/dev/null | grep -c '250 2.1.5 Ok'`

    if [ $LINECOUNT -ne 1 ] ; then
        herald 'The SMTP service test failed!'
        SMTP_SUCCESS=false
    else
        herald 'The SMTP service test was successful!'
        SMTP_SUCCESS=true
    fi
}

function test_imap {
    local HOST=$1
    local LINECOUNT=`(
        echo ". login $TESTUSR $TESTPWD"
        sleep 1
        echo ". logout"
    ) | openssl s_client -connect $HOST:993 2>/dev/null | grep -c '. OK Logged in.'`

    if [ $LINECOUNT -ne 1 ] ; then
        herald 'The IMAP4 service test failed!'
        IMAP_SUCCESS=false
    else
        herald 'The IMAP4 service test was successful!'
        IMAP_SUCCESS=true
    fi
}

function test_pop {
    local HOST=$1
    local LINECOUNT=`(
        echo "user $TESTUSR"
        sleep 1
        echo "pass $TESTPWD"
        sleep 1
        echo "quit"
    ) | openssl s_client -connect $HOST:995 2>/dev/null | grep -c '+OK Logged in.'`

    if [ $LINECOUNT -ne 1 ] ; then
        herald 'The POP3 service test failed!'
        POP_SUCCESS=false
    else
        herald 'The POP3 service test was successful!'
        POP_SUCCESS=true
    fi
}

function test_tftp {
    local HOST=$1
    if [ `sudo -u $SESUSR $session command $HOST "cat /opcf/Configuration/$HOST.conf | grep -ic rhel"` -eq 1 ] ; then
        sudo -u $SESUSR $session command $HOST ln -sf /tftpboot /var/lib/tftpboot
        if [ `sudo -u $SESUSR $session command $HOST 'test -L /var/lib/tftpboot && echo success'` == success ] ; then
            herald 'Successfully created needed symlink, proceeding...'
            if [ `sudo -u $SESUSR $session command $HOST 'touch /var/lib/tftpboot/proof && chmod 666 /var/lib/tftpboot/proof && echo success'` == success ] ; then
                herald 'Successfully created proof, proceeding...'
            else
                herald 'Could nog touch /var/lib/tftpboot/proof'
            fi
        else
            herald 'Needed symlink not found!'
        fi
    else
        if [ `sudo -u $SESUSR $session command $HOST 'touch /var/lib/tftpboot/proof && echo success'` == success ] ; then
            herald 'Successfully created proof, proceeding...'
        else
            herald 'Could nog touch /var/lib/tftpboot/proof'
        fi
    fi

    tftp $HOST -c get proof
    if [ $? != 0 ] ; then
        herald 'The TFTP service test failed!'
        TFTP_SUCCESS=false
    else
        herald 'The TFTP service test was successful!'
        TFTP_SUCCESS=true
        rm -rf ./proof
    fi
}

function test_http {
    local HOST=$1
    wget http://$HOST/ -o /dev/null -O /dev/null
    if [ $? != 0 ] ; then
        herald 'The HTTP service test failed!'
        HTTP_SUCCESS=false
    else
        herald 'The HTTP service test was successful!'
        HTTP_SUCCESS=true
        rm -f index.html
    fi
}

function test_dns {
    local HOST=$HOST
    dig @$HOST www.openpcf.org >/dev/null
    if [ $? != 0 ] ; then
        herald 'The DNS service test failed!'
        DNS_SUCCESS=false
    else
        herald 'The DNS service test was successful!'
        DNS_SUCCESS=true
    fi
}

function test_ntp {
    local HOST=$1
    ntpdate -q $HOST >/dev/null
    if [ $? != 0 ] ; then
        herald 'The NTP service test failed!'
        NTP_SUCCESS=false
    else
        herald 'The NTP service test was successful!'
        NTP_SUCCESS=true
    fi
}

function test_smb {
    local HOST=$1
    smbclient -L \\$HOST -U $TESTUSR%$TESTPWD >&/dev/null
    if [ $? != 0 ] ; then
        herald 'The SMB service test failed!'
        SMB_SUCCESS=false
    else
        herald 'The SMB service test was successful!'
        SMB_SUCCESS=true
    fi
}

function test_dhcp {
    local HOST=$1
    dhcping -v -i -s $HOST >/dev/null
    if [ $? != 0 ] ; then
        herald 'The DHCP service test failed!'
        DHCP_SUCCESS=false
    else
        herald 'The DHCP service test was successful!'
        DHCP_SUCCESS=true
    fi
}

function test_nfs {
    local HOST=$1
    mount $HOST:/var/public /mnt
    if [ $? != 0 ] ; then
        herald 'The NFS service test failed!'
        NFS_SUCCESS=false
    else
        herald 'The NFS service test was successful!'
        NFS_SUCCESS=true
        umount /mnt
    fi
}

function test_ldap {
    local $HOST=$1
    if [ `sudo -u $SESUSR $session command $HOST grep -ic ldap /etc/hosts` -ge 1 ] ; then
        herald 'ldap.example.com found in /etc/hosts...'
    else
        sudo -u $SESUSR $session command $HOST echo "127.0.0.1 ldap.example.com >> /etc/hosts"
        herald 'added ldap.example.com to /etc/hosts...'
    fi

    local SUCCESS=`sudo -u $SESUSR $session command $HOST 'ldapsearch -b dc=example,dc=com -H ldaps://ldap.example.com/ -x ou=* >/dev/null && echo success'`
    if [ $SUCCESS == success ] ; then
        herald 'The LDAP service test was successfull!'
        LDAP_SUCCESS=true
    else
        herald 'The LDAP service test failed!'
        LDAP_SUCCESS=false
    fi
}

function test_cfengine {
    local HOST=$1
    if [ `sudo -u $SESUSR $session command $HOST "ps -ef | grep cfservd | grep -v grep|wc -l"` -ge  1 ] ; then
        herald 'The CFENGINE service test was successfull!'
        CFENGINE_SUCCESS=true
    else
        herald 'The CFENGINE service test failed!'
        CFENGINE_SUCCESS=false
    fi
}

function show_result {
echo "    <host colour=\"green\">
        <name>${HOST}</name>
        <services>

            <service>
                <name>DNS</name>
                <pass>${DNS_SUCCESS}</pass>
            </service>

            <service>
                <name>NTP</name>
                <pass>${NTP_SUCCESS}</pass>
            </service>

            <service>
                <name>DHCP</name>
                <pass>${DHCP_SUCCESS}</pass>
            </service>

            <service>
                <name>SMTP</name>
                <pass>${SMTP_SUCCESS}</pass>
            </service>

            <service>
                <name>HTTP</name>
                <pass>${HTTP_SUCCESS}</pass>
            </service>

            <service>
                <name>IMAP</name>
                <pass>${IMAP_SUCCESS}</pass>
            </service>

            <service>
                <name>POP</name>
                <pass>${POP_SUCCESS}</pass>
            </service>

            <service>
                <name>NFS</name>
                <pass>${NFS_SUCCESS}</pass>
            </service>

            <service>
                <name>SMB</name>
                <pass>${SMB_SUCCESS}</pass>
            </service>

            <service>
                <name>TFTP</name>
                <pass>${TFTP_SUCCESS}</pass>
            </service>

            <service>
                <name>LDAP</name>
                <pass>${LDAP_SUCCESS}</pass>
            </service>

            <service>
                <name>CFENGINE</name>
                <pass>${CFENGINE_SUCCESS}</pass>
            </service>

        </services>
    </host>"
}

function add_linux_user {
    if [ `sudo -u $SESUSR $session command $HOST adduser $TESTUSR && echo success` == success ] ; then
        sudo -u $SESUSR $session command $HOST "echo $TESTPWD|passwd --stdin $TESTUSR"
    fi
}

function add_bsd_user {
    sudo -u $SESUSR $session command $HOST "/usr/sbin/useradd -p \$(/usr/bin/pwhash $TESTPWD) -m $TESTUSR"
}

function get_platform {
    local UNAME=`sudo -u $SESUSR $session command $HOST uname`

    if [ `echo "$UNAME" | grep -ic solaris` -ge 1 ] ; then
        PLATFORM=solaris
    elif [ `echo "$UNAME" | grep -ic hp-ux` -ge 1 ] ; then
        PLATFORM=hpux
    elif [ `echo "$UNAME" | grep -ic aix` -ge 1 ] ; then
        PLATFORM=aix
    elif [ `echo "$UNAME" | grep -ic linux` -ge 1 ] ; then
        PLATFORM=linux
    elif [ `echo "$UNAME" | grep -ic bsd` -ge 1 ] ; then
        PLATFORM=bsd
    else
        PLATFORM=unknown
        herald 'Could not reliably determine platform!'
    fi
}

function chk_platform_prerequisites {
    local HOST=$1
    get_platform
    case "$PLATFORM" in
        "linux")
            if [ `sudo -u $SESUSR $session command $HOST grep -wc $TESTUSR /etc/passwd` -ge 1 ] ; then
                herald "We have a user '$TESTUSR'"
            else
                herald "We need a user '$TESTUSR', creating one..."
                add_linux_user
                if [ `sudo -u $SESUSR $session command $HOST grep -wc $TESTUSR /etc/passwd` -ge 1 ] ; then
                    herald "We have created a user '$TESTUSR'"
                else
                    herald "failed creating user '$TESTUSR', exiting!"
                    exit 3
                fi
            fi
            ;;
        "solaris")
            herald 'This platform is not yet implemented, exiting!'
            exit 4
            ;;
        "aix")
            herald 'This platform is not yet implemented, exiting!'
            exit 4
            ;;
        "hpux")
            herald 'This platform is not yet implemented, exiting!'
            exit 4
            ;;
        "bsd")
            if [ `sudo -u $SESUSR $session command $HOST grep -wc $TESTUSR /etc/passwd` -ge 1 ] ; then
                herald "We have a user '$TESTUSR'"
            else
                herald "We need a user '$TESTUSR', creating one..."
                add_bsd_user
                if [ `sudo -u $SESUSR $session command $HOST grep -wc $TESTUSR /etc/passwd` -ge 1 ] ;  then
                    herald "We have created a user '$TESTUSR'"
                else
                    herald "failed creating user '$TESTUSR', exiting!"
                    exit 3
                fi
            fi
            ;;
        *)
            herald 'We do not know what we are working with here, exiting'
            exit 3
            ;;
    esac

    return 0
}

###############################################################################
################################# ACTUAL CODE #################################
###############################################################################
have_root
make_logfile
make_outfile
have_dig
have_ntpdate
have_dhcping
have_telnet
have_wget
have_openssl
have_smbclient
have_tftp
have_session

for HOST in `sudo -u $SESUSR $session check $TSTGRP | grep ": .*on.*" | awk -F ':' '{print $1}'`; do
    herald "We are currently working with $HOST."

    chk_platform_prerequisites $HOST
    if [ $? != 0 ] ; then
        herald 'The prerequisites for the host are not met, exiting!'
        continue
    else
        herald 'Prerequisites for the host are met, proceeding...'
    fi

    test_dns $HOST
    test_ntp $HOST
    test_dhcp $HOST
    test_smtp $HOST
    test_http $HOST
    test_imap $HOST
    test_pop $HOST
    test_smb $HOST
    test_nfs $HOST
    test_tftp $HOST
    test_ldap $HOST
    test_cfengine $HOST
    show_result >> $OUTPUTFILE
done
close_outfile
herald 'Done!'

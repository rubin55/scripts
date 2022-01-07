#!/bin/sh 

##############################
# tempchk.sh                 #
#                            #
# check disk-temps in areca  #
# against predefined min/max #
#                            #
# exit 0 - everything cool   #
# exit 1 - config error      #
# exit 2 - temperature error #
#                            #
# TODO: parameterize script  #
# TODO: implement mail/sms   #
##############################

# settings
ARECA_URL=""
ARECA_USER=""
ARECA_PASS=""
MIN_TEMP=30
MAX_TEMP=40

# don't change
HWMON_URL="$ARECA_URL/hwmon.htm"
HWMON_RES=$(curl -s --digest -u $ARECA_USER:$ARECA_PASS $HWMON_URL)

# check settings
if [ -z "$MAX_TEMP" -o -z "$MIN_TEMP" ] ; then
    echo "ERROR: invalid settings detected, please set MIN/MAX values, exiting..."
    exit 1
elif [ $MAX_TEMP -le $MIN_TEMP -o $MIN_TEMP -le 0 ] ; then
    echo "ERROR: invalid settings detected, please check your MIN/MAX settings, exiting..."
    exit 1
fi
if [ -z "$HWMON_RES" ] ; then
    echo "Empty result, please check user/pass/url settings, exiting..."
    exit 1
fi

# check if session still valid
if [ $(echo $HWMON_RES | grep -c 'Please Restart') -gt 0 ] ; then
    #echo "NOTICE: Session interrupted, initializing HTTP session"
    curl -s --digest -u $ARECA_USER:$ARECA_PASS http://172.17.1.22 > /dev/null 2>&1
fi

# grab the highest disk temperature
HIGH_TEMP=$(curl -s --digest -u $ARECA_USER:$ARECA_PASS $HWMON_URL | \
            grep -A 1 "Hdd" | sed -e 's|<[^>]*>||g' | grep -v "^--" | \
            awk 'BEGIN{HI=0}/^[0-9]/{if(HI<$1)HI=$1}END{print HI}')

# check if temperature is within allowed range
if [ $HIGH_TEMP -lt $MIN_TEMP -o $HIGH_TEMP -gt $MAX_TEMP ] ; then
    echo "ERROR: Highest Disk Temperature ($HIGH_TEMP) not within allowed range ($MIN_TEMP-$MAX_TEMP)"
    exit 2
fi

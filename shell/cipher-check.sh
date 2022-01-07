#!/bin/bash

read -p "SERVER/WEBSITE: " SERVER_V
SERVER=$SERVER_V
read -p "SSL PORT: " PORT_V
PORT=$PORT_V
DELAY=1
ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')

echo Obtaining cipher list from $(openssl version).

for cipher in ${ciphers[@]}
do
echo -n Testing $cipher...
result=$(echo -n | openssl s_client -cipher "$cipher" -connect $SERVER:$PORT 2>&1)
if [[ "$result" =~ "Cipher is ${cipher}" || "$result" =~ "Cipher :" ]] ; then
echo YES
else
if [[ "$result" =~ ":error:" ]] ; then
error=$(echo -n $result | cut -d':' -f6)
echo NO \($error\)
else
echo UNKNOWN RESPONSE
echo $result
fi
fi
sleep $DELAY
done


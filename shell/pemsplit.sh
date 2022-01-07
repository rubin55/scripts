#!/bin/sh

worklist="`ls *.pem`"

for file in $worklist; do
    cert="`echo "$file"|sed 's|.pem|.crt|g'`"
    key="`echo "$file"|sed 's|.pem|.key|g'`"
    openssl x509 -in "$file" > "$cert"
    openssl rsa -in "$file" > "$key"
done

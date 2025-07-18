#!/bin/sh

SEARCHMYVM=192.168.248.97

if [ "$1" ]; then
    QUERY_STRING="$1"
else
    echo $"Usage: $0 {query_string}"
    echo $"Example: $0 datastore.freeSpace"
    exit 1
fi

# JSession Cookie setup:
wget -q --cookies=on --keep-session-cookies --save-cookies=/tmp/cookie.txt \
     http://$SEARCHMYVM/servlets/Settings.jsp \
     -O /tmp/session.out


# Ajax Session setup:
MODES="202 301 303 203"
for MODE in $MODES; do
    wget -q --referer=$SEARCHMYVM/ --cookies=on --load-cookies=/tmp/cookie.txt \
         --keep-session-cookies --save-cookies=/tmp/cookie.txt \
         --post-data="mode=$MODE" \
         http://$SEARCHMYVM/servlets/AjaxServlet \
         -O /tmp/ajax.out
done;


# Prepare query:
wget -q --referer=$SEARCHMYVM/ --cookies=on --load-cookies=/tmp/cookie.txt \
     --keep-session-cookies --save-cookies=/tmp/cookie.txt \
     --post-data="searchMode=checkQuery&queryString=$QUERY_STRING" \
     http://$SEARCHMYVM/servlets/AjaxServlet \
     -O /tmp/ajax.out

# Load results:
wget -q --referer=$SEARCHMYVM/ --cookies=on --load-cookies=/tmp/cookie.txt \
     --keep-session-cookies --save-cookies=/tmp/cookie.txt \
     --post-data="start=0&limit=10&queryString=$QUERY_STRING&sort=parent&dir=DESC" \
     http://$SEARCHMYVM/servlets/AjaxServlet?searchMode=loadResult \
     -O /tmp/ajax.out

# Export results:
wget -q --referer=$SEARCHMYVM/ --cookies=on --load-cookies=/tmp/cookie.txt \
     --keep-session-cookies --save-cookies=/tmp/cookie.txt \
     --post-data="queryString=$QUERY_STRING" \
     http://$SEARCHMYVM/servlets/XMLServlet \
     -O  /tmp/xml.out

# Return results:
cat /tmp/xml.out

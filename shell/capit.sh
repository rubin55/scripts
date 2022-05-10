#!/bin/sh
IFS=$'\x09'$'\x0A'$'\x0D'
MUSICDIR=/home/rubin/desktop/Import

echo "Inspecting $MUSICDIR's directories. Please be patient!"
for DIRECTORY in `find $MUSICDIR -type d`; do
    OLD=$DIRECTORY
    CAPPED_MUSICDIR=`echo $MUSICDIR | sed -f capit.sed`
    NEW=`echo $OLD  | sed -f capit.sed \
                    | sed "s|$CAPPED_MUSICDIR|$MUSICDIR|g" \
                    | sed "s| i | I |g" \
                    | sed "s|^i |^I |g" \
                    | sed "s| a | A |g" \
                    | sed "s|^a |^A |g"`
    TMP=`echo $NEW`.tmp
    if [ ! "$OLD" = "$NEW" ]; then
        echo "Found inconsistent name:"
        echo " * Renaming: $OLD"
        echo " * New Name: $NEW"
        mv $OLD $TMP
        mv $TMP $NEW
        echo ""
    fi;
done;

echo "Inspecting $MUSICDIR's files. Please be patient!"
for FILE in `find $MUSICDIR -type f | sed -n '/\ [a-z]/p'`; do
    DIR=`dirname $FILE`
    OLD=`echo $FILE | awk -F\/ '{print $8}'`
    NEW=`echo $OLD  | sed -f capit.sed \
                    | sed "s/Mp3/mp3/g" \
                    | sed "s/M4a/m4a/g" \
                    | sed "s| i | I |g" \
                    | sed "s|^i |^I |g" \
                    | sed "s| a | A |g" \
                    | sed "s|^a |^A |g"`
    TMP=`echo $NEW`.tmp
    if [ ! "$OLD" = "$NEW" ]; then
        echo "Found inconsistent name:"
        echo " * Renaming: $OLD"
        echo " * New Name: $NEW"
        mv $DIR/$OLD $DIR/$TMP
        mv $DIR/$TMP $DIR/$NEW
        echo ""
    fi;
done;

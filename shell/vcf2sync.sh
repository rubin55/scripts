#!/bin/sh

OUTPUT_DIR=~/Desktop/output
SYNCML_DIR=~/.opensync/work/contacts

if [ ! -d $OUTPUT_DIR ]; then
    echo "No output directory with vcf files found!"
    echo "Export your vcards from thunderbird first."
    exit 1
fi;

if [ ! -d $SYNCML_DIR ]; then
    echo "No syncml directory for writing found!"
    echo "You need to set up a file sync first."
    exit 1
fi;

COUNT=1
for ORIG in `ls $OUTPUT_DIR`; do
    echo Exporting $ORIG to $SYNCML_DIR/$COUNT
    mv $OUTPUT_DIR/$ORIG $SYNCML_DIR/$COUNT
    COUNT=`expr $COUNT "+" 1`
done;



# /etc/profile.d/python.sh - setup python environment


# Check if input is given.
if [ -z $1 ]; then
    # Set defaults to system's python.
    PYTHONDIR="/usr"
    PYTHONBIN="$PYTHONDIR/bin/python"
    PYTHONVER="`$PYTHONBIN -c 'import sys; print(sys.version[:3])'`"
else
    # Input was given, act accordingly.
    PYTHONBASE="/opt/python"
    PYTHONDIR="$PYTHONBASE/python-$1"
    PYTHONBIN="$PYTHONDIR/bin/python"

    INPUT="`echo "$1" | sed 's|-||g'`"
    VALID="`ls -d $PYTHONBASE/* | cut -d "-" -f 2`"
    VERIFY="`echo $VALID | grep $INPUT`"
    if [ ! -z "$VERIFY" ]; then
        # Valid input was obtained, check for python executable.
        if [ -x "$PYTHONBIN" ]; then
            PYTHONVER="`$PYTHONBIN -c 'import sys; print(sys.version[:3])'`"
        else
            echo "$PYTHONBIN does not exist or is not (the correct) executable."
            echo ""
            exit 1
        fi;
    else
        echo "Invalid python version specified. Please select a valid version."
        echo "Valid versions:"
        echo "$VALID"
        echo ""
        exit 1
    fi;
fi;

# Add python to first PATH element.
echo ${PATH} | egrep -q "(^|:)${PYTHONDIR}/bin($|:)"
if [ $? == 1 ]; then
    PATH="${PYTHONDIR}/bin:${PATH}"
fi;

# Check /opt for python package directories and add if not in PYTHONPATH.
PYTHONPKGS="lib/python$PYTHONVER/site-packages"
PYTHONPATH=""
for DIR in `ls -d /opt/*`; do
    if [ -d "$DIR/$PYTHONPKGS" ]; then 
        echo ${PYTHONPATH} | egrep -q "(^|:)$DIR/$PYTHONPKGS($|:)"
        if [ $? == 1 ]; then
            PYTHONPATH="${PYTHONPATH}:$DIR/$PYTHONPKGS"
        fi;
    fi;
done;

export PATH
export PYTHONPATH

# If we have valid input, show some info.
if [ ! -z "$VALID" ]; then
    SOURCED=`echo $0 | grep bash`
    if [ -z $SOURCED ]; then
        echo "I would set the python environment like the following:"
        echo "(do \"source `basename $0` $1\" to make it so)"
    fi;
    echo ""
    echo PYTHONDIR: $PYTHONDIR
    echo PYTHONBIN: $PYTHONBIN
    echo PYTHONVER: $PYTHONVER
    echo PYTHONPATH: $PYTHONPATH
    echo PATH: $PATH
fi;

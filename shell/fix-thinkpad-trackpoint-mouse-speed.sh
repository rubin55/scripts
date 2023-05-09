#!/bin/bash

# Only run on ThinkPads.
lsmod | grep -q thinkpad_acpi
if [ $? -gt 0 ]; then
    echo "Not a thinkpad, exiting.."
    exit $?
fi

# Which device do you want to adjust for.
id=14

# Make sure xinput commands can interact with display.
export DISPLAY=:1
export XAUTHORITY=/run/user/1001/gdm/Xauthority

# Wait for trackpoint device to appear.
until xinput list $id > /dev/null 2>&1 ; do
    echo "Waiting for device $id to appear.."
    sleep 1
done

# Tell us about what we're doing.
echo "DISPLAY=$DISPLAY"
echo "EXECUTING_USER=$USER"
echo "EXECUTION_DATE=`date`"
echo ""

# Run the xinput commands to increase mouse speed.
xinput set-prop $id "Coordinate Transformation Matrix" 1.0, 0, 0, 0, 1.0, 0, 0, 0, 0.67
xinput set-prop $id "libinput Accel Speed" 0.5

# List available devices.
echo "List of devices:"
xinput list
echo ""

# List properties of adjusted device.
echo "List of device $id properties:"
xinput --list-props $id
echo ""

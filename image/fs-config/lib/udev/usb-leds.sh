#!/bin/sh

LED=`echo $DEVPATH | sed -r 's/.*\/\w-\w\.(\w)\/.*/\1/'`

if [ "${ACTION}" = "add" ]; then
	echo 1 >/sys/class/leds/usb${LED}:blue/brightness
else
	echo 0 >/sys/class/leds/usb${LED}:blue/brightness
fi
	
exit 0


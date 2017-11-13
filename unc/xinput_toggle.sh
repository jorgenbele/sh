#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2015 [dd.mm.yyyy]
# File: xinput_toggle.sh 
# Description: Uses xinput to toggle devices.
# Dependencies: xinput
state=$(xinput -list-props "$1" | grep "Device Enabled" | grep -o "[01]$")

if [ "$state" = "1" ]; then
    xinput disable "$1"
else
    xinput enable "$1"
fi


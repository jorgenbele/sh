#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2016 [dd.mm.yyyy]
# File: dmenu_start.sh
# Description: 
#   Runs dmenu_run using custom font and color.

color="#212C2F"
if [ -f "/tmp/fontsize" ]; then
    fontsize=$(cat "/tmp/fontsize")
else
    fontsize="18"
fi

font="xft:Source Code Pro:pixelsize=$fontsize"

dmenu_run -sb "$color" -fn "$font"

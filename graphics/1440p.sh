#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2016 [dd.mm.yyyy]
# File: 1440.sh
# Description: 
#   Tries to set the current xrandr output to 1440p.

CMON="$(xrandr --listactivemonitors | head -2 | tail -1 | awk '{print $4}')"

xrandr --output "$CMON" --mode 2560x1440
notification -t 10 -a "resolution: 1440p" &
change-dpi 150
reset-bar 20

sh ~/.fehbg

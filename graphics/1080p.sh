#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2016 [dd.mm.yyyy]
# File: 1080p.sh
# Description: 
#   Tries to set the current xrandr output to 1080p.

CMON="$(xrandr --listactivemonitors | head -2 | tail -1 | awk '{print $4}')"

xrandr --output "$CMON" --mode 1920x1080 
notification -t 10 -a "resolution: 1080p" &

change-dpi 0
reset-bar 16
sh ~/.fehbg

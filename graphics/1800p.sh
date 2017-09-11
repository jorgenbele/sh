#!/bin/sh
CMON="$(xrandr --listactivemonitors | head -2 | tail -1 | awk '{print $4}')"

xrandr --output "$CMON" --mode 3200x1800 
notification -t 10 -a "resolution: 1800p" &
change-dpi 180
reset-bar 23
sh ~/.fehbg

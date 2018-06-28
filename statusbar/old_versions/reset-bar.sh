#!/bin/sh
case $# in
    0) fontsize="26";;
    1) fontsize="$1";;
esac

echo "fontsize: $fontsize"
font="xft:Source Code Pro:pixelsize=$fontsize:antialias=true"

# kill old process(es)
pkill lemonbar 

# spawn new process
$BIN_PATH/statusbar | ~/bin/lemonbar -f "$font" &

echo "$fontsize" > /tmp/fontsize

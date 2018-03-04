#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 04.03.2018 [dd.mm.yyyy]
# File: officefarm.sh
# Description: 
#   Connect to NTNU's officefarm remote desktop.
read_() {
    printf "$1: "
    read "$2"
}

if [ "$1" = "-h" ]; then
    printf "Usage: $0 [USERNAME WINDOW_SIZE]\n"
    printf "Connects to NTNU's officefarm windows remote desktop."
    printf "Default window size is 1920x1080.\n"
    printf "Uses environment variable RUSERNAME as username if set.\n"
    exit 1
fi

if [ -z "$RUSERNAME" ]; then
    [ -n "$1" ] && RUSERNAME="$1" || read_ "Username" RUSERNAME
fi
if [ -z "$RSIZE" ]; then
    [ -n "$2" ] && RSIZE="$2" || RSIZE="1920x1080"
fi
xfreerdp -d win.ntnu.no  -u "$RUSERNAME" -v officefarm.ntnu.no -size "$RSIZE" -smart-sizing

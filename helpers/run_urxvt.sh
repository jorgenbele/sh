#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2016 [dd.mm.yyyy]
# File: run_urxvt.sh
# Description: 
#   Used to run urxvt, it first starts the daemon
#   if none is running and then starts a new client.

flags=""
cflags="+sb"
urxvtc "$@" $cflags
if [ $? -eq 2 ]; then
    urxvtd -q -o -f $flags 
    urxvtc "$@" $cflags
fi


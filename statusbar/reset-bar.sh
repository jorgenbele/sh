#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.07.2017 [dd.mm.yyyy]
# File: reset-bar.sh
# Description: 
#   Script to kill off old statusbar (related) processes and start a new one.
# Dependencies: statusbar (and lemonbar)

# kill old process(es)
killall -e statusbar 
killall -e status 
killall -e lemonbar

# start new
statusbar "$@"

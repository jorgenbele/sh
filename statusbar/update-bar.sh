#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.07.2017 [dd.mm.yyyy]
# File: update-bar.sh
# Description: 
#   Force updates the statusline generator 'status' by 
#   sending it a -USR1 signal.
# Dependencies: status, lemonbar

pkill -o -f "status" -USR1

#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2015 [dd.mm.yyyy]
# File: change-dpi.sh
# Description: Changes the xft font dpi by merging X resources.
# Dependencies: xrdb
#!import commands.*
dependencies="xrdb"
USAGE_TEXT="DPI"
default_setup "$@"

change_dpi() {
    tmpf="$(mktemp)"
    echo "Xft.dpi: $1" > "$tmpf"
    xrdb -merge "$tmpf"
    rm "$tmpf"
}

if [ -z "$1" ]; then
    default_usage
    exit 1
fi

change_dpi "$1"


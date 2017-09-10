#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2015 [dd.mm.yyyy]
# File: change-dpi.sh
# Description: Changes the xft font dpi by merging X resources.
# Dependencies: xrdb

change_dpi() {
    tmpf="$(mktemp)"
    echo "Xft.dpi: $1" > "$tmpf"
    xrdb -merge "$tmpf"
    rm "$tmpf"
}

case "$1" in
    ""|"-h") echo "Usage: $0 [-h] <dpi>"
        ;;
    *) change_dpi "$1"
        ;;
esac


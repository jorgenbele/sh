#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 29.06.2017 [dd.mm.yyyy]
# File: lock.sh
# Description: 
#   Starts i3lock with with a set wallpaper and 
#   unmounts ecryptfs private dir.

# Unmount ecryptfs private dir.
if [ -z "$BIN_PATH" ]; then
    BIN_PATH="$HOME/bin"
fi
eumount

# Start locker.
i3lock -i "$HOME/.wallpaper" -f

#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2016 [dd.mm.yyyy]
# File: yt.sh
# Description: 
#   Runs mpv (uses youtube-dl) to play file/stream/url from clipboard.
mpv $(xclip -o)

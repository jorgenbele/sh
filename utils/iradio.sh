#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 20.07.2017 [dd.mm.yyyy]
# File: iradio.sh
# Description: Simple cli interface to internet radios (P6 only for now).
# Dependencies: mplayer (or mplayer2)

case $1 in 
    'p6'|*) url="http://stream.p4.no/p6_mp3_mq?Nettplayer_P6.no"
esac

# start playback using PLAYER
# might specify other player (but needs to support flags used)
[ -z "$PLAYER" ] && PLAYER="mplayer"

# start player
$PLAYER $url 2>&1

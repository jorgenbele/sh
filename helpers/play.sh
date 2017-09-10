#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 16.07.2017 [dd.mm.yyyy]
# File: play.sh
# Description:
#   Shell script file to detect and play streams and files.

# Currently supports:
# - http(s) playback
# - file playback
# - stream playback
#
# Dependencies: 
# - youtube-dl (youtube, ++)
# - mplayer or another player supporting playback from stdin


# SETUP
if [ -z "$PLAYER_CMD" ]; then
    PLAYER_CMD="mplayer"
fi

if [ -z "$PLAYER_OPTS" ]; then
    PLAYER_OPTS="-"
fi

# usage 
usage() {
    echo "Usage: $0 [-h] [-p PLAYER] [-o PLAYER_OPTS]"
}


# getopt
TEMP=$(getopt -o 'hp:o:' -n "$0" -- "$@")
eval set -- "$TEMP"

if [ "$?" -ne 0 ]; then
    echo "getopt failed" 1>&2
    exit 1
fi

# handle options
while true; do
    case "$1" in
        '-h')   usage; exit 0 ;;
        '-p')   PLAYER_CMD="$2";  shift 2; continue ;;
        '-o')   PLAYER_OPTS="$2"; shift 2; continue ;;
        '--')   shift; break ;;
        *)      echo "unknown option '1'" 1>&2; exit 1 ;;
    esac
done

if [ "$#" -eq 0 ]; then
    $PLAYER_CMD $PLAYER_OPTS
else
    # handle files/streams/links
    while true; do
        case "$1" in
            http*) 
                # start with youtube-dl 
                youtube-dl --no-part -o - "$1" | $PLAYER_CMD $PLAYER_OPTS
                shift
                ;;
            -)
                $PLAYER_CMD $PLAYER_OPTS
                shift
                ;;
            **)  
                # start player
                $PLAYER_CMD $PLAYER_OPTS < "$1"
                shift
                ;;
            *) break; ;;
        esac
    done
fi


#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 04.03.2018 [dd.mm.yyyy]
# File: officefarm.sh
# Description: 
#   Connect to NTNU's officefarm remote desktop.

#!import commands.has_commands.
#!import commands.check_deps
#!import commands.logf
#!import commands.log
#!import commands.verbose

dependencies="xfreerdp"

VERBOSE=false

read_() {
    printf "$1: "
    read "$2"
}

usage() {
    printf "Usage: $(basename $0) [-hvd] [-u USERNAME] [-s SIZE] [USERNAME WINDOW_SIZE]\n"
    printf "Connects to NTNU's officefarm windows remote desktop."
    printf "Default window size is 1920x1080.\n"
    printf "Uses environment variable RUSERNAME as username if set.\n"
}

opts="dhvu:s:"
while getopts "$opts" arg; do
    case "$arg" in
        'v') VERBOSE=true;              ;;
    esac
done
OPTIND=1

while getopts "$opts" arg; do
    case "$arg" in
        'd') check_deps; exit "$?"; ;;
        'h') usage; exit 0;         ;;
        'u') RUSERNAME="$OPTARG";   ;;
        's') RSIZE="$OPTARG";       ;;
        '?') log "Internal error: $arg" ;;
    esac
done


if [ -z "$RUSERNAME" ]; then
    [ -n "$1" ] && RUSERNAME="$1" || read_ "Username" RUSERNAME
fi
if [ -z "$RSIZE" ]; then
    [ -n "$2" ] && RSIZE="$2" || RSIZE="1920x1080"
fi
xfreerdp -d win.ntnu.no  -u "$RUSERNAME" -v officefarm.ntnu.no -size "$RSIZE" -smart-sizing

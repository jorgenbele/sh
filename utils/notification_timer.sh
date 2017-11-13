#!/bin/sh
# Author: Jørgen Bele Reinfjell
# Date: 13.11.2017 [dd.mm.yyyy]
# File: notification_timer.sh
# Description: Shows a timer notification.
# Dependencies: notification.sh [notification]

SLEEP_TIME=1
TIME_SEP=":"

tsec() { date +"%s"; }

pps() {
    local ts="$1"
    d="$(($ts/(24*3600)))"
    h="$(($ts/(3600)))"
    m="$((($ts%3600)/60))" 
    s="$(($ts%60))" 
    
    sep=""

    [ "$d" -gt 0 ] && printf "%dd" "${d}" && sep="$TIME_SEP"
    [ "$h" -gt 0 ] && printf "%s%dh" "$sep" "${h}" && sep="$TIME_SEP"
    [ "$m" -gt 0 ] && printf "%s%dm" "$sep" "${m}" && sep="$TIME_SEP"
    [ "$s" -gt 0 ] && printf "%s%ds" "$sep" "${s}" && sep="$TIME_SEP"
}

dtime() {
    local startt="$1"
    local endt="$2"

    [ -z "$startt" ] || [ -z "$endt" ] && exit 1
    local time="$(($endt - $startt))"
    pps "$time"
}

timer() {
    local startt="$(tsec)"

    while true; do
        # Get running time in seconds
        local time="$(tsec)"
        dtf="$(dtime $startt $time)"

        # Update notification
        notification -k "timer" -a "$dtf"
        sleep "$SLEEP_TIME"
    done
}

timer

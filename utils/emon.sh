#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2016 [dd.mm.yyyy]
# File: emon.sh
# Description: A script for easy handling of external monitors
# Dependencies: xrandr 

## emon (Extenal MONitor utility)
## A script for easier handling of external monitors. 
## Uses the 'xrandr' utility to control monitors.

## CURRENTLY FUCKING BUGGY AS ALL HELL
## BUT IT SERVES IT'S PURPOSE, SOMETIMES

DEFAULT_SIDE="right"

compile_cmd() {
    cmd="xrandr --output $@"
    echo "$cmd"
}

monitor=""
source_monitor=""

__select_monitor_if_routine() {
    #echo "No such monitor: $1"
    #echo "Select monitor from the following list: "

    i=1
    for m in $monitors; do
	echo "($i) $m"
	i=$((i+1))
    done

    read num

    #monitor=$(echo $monitors | head -n "$((num))" | tail -1)
    #echo $monitors | awk "{print \$"$num"}"

    monitor=$(echo $monitors | awk "{print \$"$num"}")
    #echo "You chose $monitor" 
}

select_monitor() {
    monitors="$(xrandr -q | grep connected | awk '{print $1}')"
#    monitors="hdmi
#eDP1"

    # if $1 is not in the list of monitors ask for a monitor
    if [ "$1" = "" ]; then
	__select_monitor_if_routine
    else 
	echo "Using monitor: $1"
	monitor="$1"
    fi
}

select_side() {
    echo "--right-of $1"
}

extend() {
    # $1 - monitor
    # $2 - side
    # $3 - source monitor
    # $4 - resolution (not implemented)

    echo "Main/source monitor:"
    select_monitor "$3"
    source_mon="$monitor"

    echo "Monitor:"
    select_monitor "$1"

    compile_cmd  "$monitor" "--noprimary" "$(select_side $2 $source_mon)" "--auto"
}

duplicate() {
    # $1 - monitor
    # $2 - source monitor (to duplicate)
    echo "Main/source monitor:"
    select_monitor "$2"
    source_mon="$monitor"

    echo "Monitor:"
    select_monitor "$1"
    compile_cmd "$monitor" "--same-as $source_mon" "--auto"
}


disable() {
    # $1 - monitor
    select_monitor "$1"
    compile_cmd "$monitor" "--off"
}

off() {
    disable "$@"
}

#extend "$1" "$2" "$3" "$4"
#duplicate "$1" "$2" "$3" "$4"
#disable "$1" "$2" "$3" "$4"

"$1" "$2" "$3" "$4" "$5"
$cmd

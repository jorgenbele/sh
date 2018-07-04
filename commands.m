#!/bin/sh
# Author: Jørgen Bele Reinfjell
# Date: 14.06.2017 [dd.mm.yyyy]
# Modified: 15.09.2017 [dd.mm.yyyy]
# Modified: 13.11.2017 [dd.mm.yyyy]
# File: commands.sh
# Description:
#   A collection of useful shell script functions.

# default_setup: helper function which sets up
# default parameters and options for my scripts.
default_setup() {
    VERBOSE=false
    default_opts "$@"
}

# default_opts: helper function passing my minimum
# requirements for displaying usage text
# Comes along with default_opts..
default_usage() {
    echo "Usage: $0 [-dhv] $USAGE_TEXT"
    if [ -n "$DESCRIPTION_TEXT" ]; then
	    echo
	    echo "Description:"
	    echo "    $DESCRIPTION_TEXT"
    fi
}

# default_opts: helper function passing my minimum
# requirements for parsing the have for script arguments.
default_opts() {
    opts="vdh"
    while getopts "$opts" arg; do
        case "$arg" in
            'v') VERBOSE=true; ;;
        esac
    done
    OPTIND=1;

    while getopts "$opts" arg; do
        case "$arg" in
            'd') check_deps; exit "$?";          ;;
            'h')
                default_usage
                exit 0; ;;
            '?') log "Internal error: $arg" ;;
        esac
    done
}

# has_cmds: checks if all the given commands exists
# returns a list of the missing dependencies
has_commands() {
    ret=0
	while [ -n "$1" ]; do
		if ! command -v "$1" > /dev/null; then
            if [ -z "$missing" ]; then
                missing="$1"
            else
                missing="$missing $1"
            fi
            ret=1
        fi
		shift 1
	done
    echo "$missing"
	return $ret
}

# check_deps: uses has_commands() to check if deps in $dependencies are resolved.
# stdout - the user readable results
check_deps() {
    missing_deps=$(has_commands $dependencies)
    if [ "$?" = 0 ]; then
        verbose "All dependencies found: $dependencies"
    else
        verbose "Missing dependencies: $missing_deps"
    fi
}

# log(...): echo for logging
log() {
    echo "$@"
}

# logf(...): printf for logging
logf() {
    printf "$@"
}


# error(...): echo redirected to stderr for errors.
error() {
    printf "$@" 1>&2
}

# errorf(...): printf redirected to stderr for errors.
errorf() {
    printf "$@" 1>&2
}

# verbose(): prints output only when VERBOSE=true
verbose() {
	"$VERBOSE" && log "$@"
}

verbosef() {
    "$VERBOSE" && logf "$@"
}

# cmd_exists(): checks if command exists
cmd_exists() {
    command -v "$1"
}

## Processes
# pstime(PID): cpu time of process with PID
#   Get the processing time of process with pid "$1" by selecting
#   the time column and resetting its header string.
pstime() {
    ps -o time= "$1"
}

# pstime(PID): user time of process with PID
#   Get the user time of process with pid "$1" by selecting
#   the time column and resetting its header string.
psetimes() {
    ps -o etimes= "$1"
}

## Strings
# join(delimiter, string ...): join strings by delimiter
join() {
    local IFSO="$IFS"
    IFS="$1"
    shift 1
    printf "$*"
    IFS="$IFSO"
}

# stripext(string ...): remove the (last) file extension
stripext() {
    echo "$@" | sed 's~\..*$~~g'
}

## Time
# tsec(): time in seconds since UNIX time epoch)
tsec() {
    date +"%s"
}

# stohms(seconds): convert seconds to hh:mm:ss
stohms() {
    local ts="$1"

    local h="$(($ts/3600))"
    local m="$((($ts%3600)/60))"
    local s="$(($ts%60))"
    printf "%02d:%02d:%02d" "$h" "$m" "$s"
}

# pps(seconds): convert seconds to a human readable format [<days>d] [<hours>h] [<minutes>m] [<seconds>s]
pps() {
    local ts="$1"

    print_if_nonzero "$(($ts/(24*3600)))" "d"
    print_if_nonzero "$(((($ts%(24*3600))/3600)))" "h"
    print_if_nonzero "$((($ts%3600)/60))" "m"
    print_if_nonzero "$(($ts%60))" "s"
}

# difftime(time): converts the time difference between time $1 and now
difftime() {
    local time="$1"
    local now="$(tsec)"

    echo $(($endt - $startt))
}

## Math
# maxint(x ...): select the largest int from list
maxint() {
    local maxv="$1"

    shift 1
    while "$1"; do
        if [ "$1" -gt "$maxv" ]; then
            maxv="$1"
        fi
        shift 1
    done
    echo "$maxv"
}

# minint(x, ...): select the smallest int from list
minint() {
    local maxv="$1"

    shift 1
    while "$1"; do
        if [ "$1" -lt "$maxv" ]; then
            maxv="$1"
        fi
        shift 1
    done
    echo "$maxv"
}

# abs(x): returns the absolute value of x
abs() {
    local x="$1"

    if [ "$x" -lt 0 ]; then
        echo "$((-$x))"
    fi
}

# is_number(x): returns true if x is a string of 10-desimal digits.
is_number() {
    echo "$1" | grep '^[0-9][0-9]*[\.]*[0-9]*$' > /dev/null
    return "$?"
}

# vim: set ft=sh:

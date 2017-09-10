#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2017 [dd.mm.yyyy]
# File: brightness.sh
# Description: 
#   Was ment to be a simplified interface to change brightness supporting
#   various different ways, but it ended up as a learning experience for
#   using getopt.

usage() {
    echo "Usage: $0 [-ghpvgx] [-sid VALUE] [-o OUTPUT]"
    echo "      -h --help               display this help and exit"
    echo "      -g --get                print current brightness value"
    echo "      -p --percentage         use percentages instead of absolute values"
    echo "      -s --set [VALUE]        set brightness value according to VALUE"
    echo "      -i --increase [VALUE]   increase brightness value according to VALUE"
    echo "      -d --decrease [VALUE]   decrease brightness value according to VALUE"
    echo "      -o --output             set output to apply brightness value to (used by xrandr)"
    echo "         --display            set display to apply brightness value to (xbacklight)"
    echo "      -v --verbose            verbose mode"
    echo "      -x --xrandr             force use of xrandr"
}

set_value_or_exit() {
    case "$1" in
        "") echo "Option $1 requires an optional argument"; exit 1 ;;
        *)  VALUE="$1" ;;
    esac
}

is_number() {
    digits="$(echo "$1" | grep '^[0-9][0-9]*[\.]*[0-9]*$')"
    return "$?"
}

perc2float() {
    clean="$(echo "$1" | sed 's/%//g')"
    printf "%.*f" "$SCALE" "$(echo "scale=$SCALE; $clean / 100" | bc)"
    return "$?"
}

float2perc() {
    printf "%.*f" "$SCALE" "$(echo "$1 * 100" | bc)"
    return "$?"
}


# get_brightness
get_brightness() {
    if [ -n "$OUTPUT" ] && [ -n $FORCE_XRANDR ]; then
        out="$(xrandr --current --verbose | grep -A 5 "$OUTPUT"  | grep "Brightness" |  awk '{print $2}')"
        ret="$?"
        "$USE_PERCENTAGE" && BRIGHTNESS="$(float2perc "$out")" || BRIGHTNESS="$out"
        echo "$BRIGHTNESS"
        return "$ret"
    fi

    if true; then
        out="$(xbacklight -get)"
        ret="$?"
        "$USE_PERCENTAGE" && BRIGHTNESS="$out" || BRIGHTNESS="$(perc2float "$out")"
        echo "$BRIGHTNESS"
        return "$ret"
    fi

    echo "Failed to get brightness" 1>&2
}

# set_brightness VALUE
set_brightness() {
    [ -z "$1" ] && echo "set_brightness(): No VALUE argument provided" 1>&2 && return 1

    # Try xrandr IF output is passed AND option is passed 
    # (note: xrandr does not actually change the backlight)
    if [ -n "$OUTPUT" ] && [ -n $FORCE_XRANDR ]; then
        "$USE_PERCENTAGE" && BRIGHTNESS="$(perc2float "$1")" || BRIGHTNESS="$1"
        [ -n "$VERBOSE_MODE" ] && echo "$BRIGHTNESS"
        xrandr --output "$OUTPUT" --brightness "$BRIGHTNESS"
        [ "$?" -eq 0 ] && return 0 # success
    fi

    # Try xbacklight
    ! "$USE_PERCENTAGE" && BRIGHTNESS="$(float2perc "$1")" || BRIGHTNESS="$1"
    [ -n "$VERBOSE_MODE" ] && echo "$BRIGHTNESS"
    # Uses percentages
    xbacklight -set "$BRIGHTNESS"
    [ "$?" -eq 0 ] && return 0 # success

    # +++ TODO: add other options +++
    echo "Failed to set brightness" 1>&2
    return 1
}


# Shell script to handle setting display brightness, using multiple methods
SHORT_OPTS="hgpxvs:i:d:o::"
LONG_OPTS="help,get,percentage,xrandr,verbose,set:,increase:,decrease:,output::"
GETOPT_OPTS="-n '$0' -- "$@""

# Check if long options are supported by checking if getopt is the "enhanced version"
# (from the man page), using the -T flag (see man getopt(1), GNU version)
getopt_out="$(getopt -T)"
getopt_ret="$?"

if [ -z "$getopt_out" ] && [ "$getopt_ret" -ne 0 ]; then
    # LONG OPTS ARE SUPPORTED
    OPTS="getopt -o $SHORT_OPTS -l $LONG_OPTS $GETOPT_OPTS"
else
    # LONG OPTS ARE NOT SUPPORTED
    OPTS="getopt -o $SHORT_OPTS $GETOPT_OPTS"

fi

# Set default values
GET_BRIGHTNESS=true
USE_PERCENTAGE=false

# modes: set=1, increase=2, decrease=#
SET_BRIGHTNESS_MODE=1
INCREASE_BRIGTHNESS_MODE=2
DECREASE_BRIGHTNESS_MODE=3
SET_MODE="$SET_BRIGHTNESS_MODE"

# Scale
SCALE=3


# Start getopt handling
[ "$VERBOSE_MODE" ] && echo "OPTS=\"$OPTS\"" 1>&2
TEMP=$($OPTS)
eval set -- "$TEMP"

# Quit if getopt failed
if [ "$?" -ne 0 ]; then
    echo "Failed..." 1>&2
    exit 1
fi

while true; do
    case "$1" in
        '-h'|'--help')       usage; exit 0 ;;
        '-g'|'--get')        GET_BRIGHTNESS=true; shift; continue ;; 
        '-p'|'--percentage') USE_PERCENTAGE=true; shift; continue ;;
        '-x'|'--xrandr')     FORCE_XRANDR=true; shift; continue ;;
        '-v'|'--verbose')    VERBOSE_MODE=1; shift; continue ;;
        '-s'|'--set')        SET_MODE="$SET_BRIGHTNESS_MODE";      set_value_or_exit "$2"; shift 2; continue ;;
        '-i'|'--increase')   SET_MODE="$INCREASE_BRIGTHNESS_MODE"; set_value_or_exit "$2"; shift 2; continue ;;
        '-d'|'--decrease')   SET_MODE="$DECREASE_BRIGHTNESS_MODE"; set_value_or_exit "$2"; shift 2; continue ;;
        '-o'|'--output'|'--display')     OUTPUT="$2"; shift 2; continue ;;
        '--')                shift; break ;;
        *)                   echo "internal error" 1>&2; exit 1 ;;
    esac
done

# Treat $0 [VALUE] as $0 -ps [VALUE]
if [ "$#" -eq 1 ]; then
   VALUE="$1" 
fi

if [ -n "$DEBUG_MODE" ]; then
    echo "GET_BRIGHTNESS=$GET_BRIGHTNESS" 1>&2
    echo "USE_PERCENTAGE=$USE_PERCENTAGE" 1>&2
    echo "FORCE_XRANDR=$FORCE_XRANDR" 1>&2
    echo "SET_MODE=$SET_MODE" 1>&2
    echo "OUTPUT=$OUTPUT" 1>&2
    echo "VALUE=$VALUE" 1>&2
fi

# Main
if $GET_BRIGHTNESS; then
    get_brightness "$OUTPUT"
    exit "$?"
fi

if [ -n "$SET_MODE" ]; then
    # Make sure VALUE is a number
    if is_number "$VALUE"; then
        case "$SET_MODE" in
            "$SET_BRIGHTNESS_MODE")      set_brightness "$VALUE" ;;
            "$INCREASE_BRIGTHNESS_MODE") echo "Increased NEW: $(get_brightness)+"$VALUE")";; #set_brightness "$($(get_brightness)+"$VALUE")" ;; # TODO 
            "$DECREASE_BRIGHTNESS_MODE") echo "Decreased NEW: $(get_brightness)-"$VALUE")";; # set_brightness "$($(get_brightness)-"$VALUE")" ;;
            *) echo "Unsupported setmode: $SE_MODE" 1>&2; exit 1 ;;
        esac
    else
        echo "Illegal number: $VALUE" 1>&2
    fi
fi

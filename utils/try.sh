#!/bin/sh
# Author: Jørgen Bele <jorgen.bele@gmail.com> 
# Date: 08.11.2017 [dd.mm.yyyy]
# File: try.sh
# Description: 
#   A simple script which repeats a command at a given interval until it
#   executes successfully (exit code 0). 

# $@ - cmd 
try_run() {
    "$@"
}

display_help() {
    echo "Usage: $0 [-t TIMEOUT] [-h]"
    echo "  -t TIMEOUT  Set timeout in seconds"
    echo "  -h          Display this message."
}

timeout=1
if [ "$1" = "-t" ]; then
    shift 1
    timeout="$1"
    if ! [ "$timeout" -gt 0 ]; then
        echo "Timeout must be a number greater than 0." >&2
        display_help >&2
        exit 1
    fi
elif [ "$1" = "-h" ]; then
    display_help
    exit 0
fi

while ! try_run "$@"; do
    sleep "$timeout"
done

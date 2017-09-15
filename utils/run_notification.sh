#!/bin/sh
# Author: Jørgen Bele Reinfjell
# Date: 15.09.2017 [dd.mm.yyyy]
# File: run_notification.sh
# Description: Shows a notification status of the program being run.
# Dependencies: notification.sh [notification]

SLEEP_TIME=5

tsec() { date +"%s"; }
print_if_nonzero() { [ "$1" -gt "0" ] && echo "$@"; }

pps() {
    local ts="$1"

    print_if_nonzero "$(($ts/(24*3600)))" "d"
    print_if_nonzero "$(((($ts%(24*3600))/3600)))" "h"
    print_if_nonzero "$((($ts%3600)/60))" "m"
    print_if_nonzero "$(($ts%60))" "s"
}

dtime() {
    local startt="$1"
    local endt="$2"

    [ -z "$startt" ] || [ -z "$endt" ] && exit 1
    local time="$(($endt - $startt))"
    pps "$time"
}

process_watcher() {
    local pid="$1"
    local name="$2"
    local startt="$3"

    # Loop until it terminates and update notification on each iteration
    local prunning=true
    while "$prunning"; do
        ! kill -s 0 "$pid" 2>/dev/null && prunning=false && break

        # Get running time in seconds
        local time="$(tsec)"
        dtf="$(dtime $startt $time)"

        # Update notification
        notification -k "$pid" -a "$name ($dtf)"
        sleep "$SLEEP_TIME"
    done

    # Remove notification of running process
    notification -d "$pid"
}

run_cmd() {
    local name="$@" # process name (argv[0])

    # Run command
    sh -c "$@" &

    local pid="$!"
    local startt="$(tsec)"

    # Quit if command failed
    if [ "$?" != 0 ]; then
        exit
    fi

    # Start watcher (in background)
    process_watcher "$pid" "$name" "$startt" &
    local pwpid="$!"
    # Set niceness level of watcher (suppress output)
    renice -n 19 "$!" > /dev/null

    # Bring process to foreground
    # fg: %% -> current job
    #     %- -> previous job
    [ -n "$(jobs)" ] && fg "%-"

    wait "$pid"

    # Create new temporary notification signifying it is finished
    local time="$(tsec)"
    dtf="$(dtime $startt $time)"
    notification -t 10 -a "$name: returned $? ($dtf)" &

    return 0
}

# Quit if no arguments are provided
case "$1" in
    "-h"|"") echo "Usage: $0 COMMAND" && exit 1 ;;
esac

# Enable job management
set -m

# Run process in background
#sh -c "sleep 10 && notification -t 5 -a DONE!" &
run_cmd "$@"

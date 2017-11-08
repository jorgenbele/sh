#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.07.2017 [dd.mm.yyyy]
# File: statusbar.sh
# Description: 
#   Starts and runs the statusline generator status
#   and pipes it's output into 'lemonbar'.
# Dependencies: status, lemonbar

### Setup

[ -z "$FONT_SIZE_FILE"   ] && FONT_SIZE_FILE="/tmp/fontsize"
[ -z "$STATUS_PIPE_FILE" ] && STATUS_FIFO_PATH="/tmp/status.pipe"
[ -z "$STATUS_PID_FILE"  ] && STATUS_PID_FILE="/tmp/status_pid"

[ -n "$LEMONBAR_CMD"  ] && lemonbar_cmd="$LEMONBAR_CMD" || lemonbar_cmd="lemonbar"
[ -n "$LEMONBAR_ARGS" ] && lemonbar_args="$LEMONBAR_ARGS"

# Fontsize
if [ -z "$FONTSIZE" ]; then
    case $# in
        0) 
            # Restore font size 
            [ -f "$FONT_SIZE_FILE" ] && NEWFONTSIZE="$(cat "$FONT_SIZE_FILE")"
            if [ -n "$NEWFONTSIZE" ]; then
                FONTSIZE="$NEWFONTSIZE"
                echo "Restoring font size: $FONTSIZE" 1>&2
            else
                FONTSIZE="23"
                echo "Using default font size: $FONTSIZE" 1>&2
            fi
            ;;
        *) FONTSIZE="$1";;
    esac
fi
[ -z "$STATUSBAR_FONT"   ] && STATUSBAR_FONT="Source Code Pro:pixelsize=$FONTSIZE:antialias=true"


### Main
echo "FONT_SIZE_FILE=$FONT_SIZE_FILE" 1>&2
echo "FONTSIZE=$FONTSIZE" 1>&2
echo "STATUSBAR_FONT=$STATUSBAR_FONT" 1>&2

# Save font size 
echo "$FONTSIZE" > "$FONT_SIZE_FILE"

# Create named pipe if not already existing.
if ! [ -p "$STATUS_FIFO_PATH" ]; then
    echo "No FIFO file, creating it now..." 1>&2
    if ! mkfifo "$STATUS_FIFO_PATH"; then
        echo "Unable to make fifo: $STATUS_FIFO_PATH\nEXITING!" 1>&2
        exit 1
    fi
fi

# Make sure no process is already running.
if [ -f "$STATUS_PID_FILE" ]; then
    echo "Process already running..." 1>&2
    echo "Killing process..." 1>&2
    kill "$(cat "$STATUS_PID_FILE")"
fi

# Start status and pipe it's output to a named pipe.
# Also set it's priority low.
echo "Starting status..." 1>&2
status 2>/dev/null > "$STATUS_FIFO_PATH" &
status_pid="$!"
renice 19 -p "$status_pid"

# Write pid to file.
echo "$status_pid" > "$STATUS_PID_FILE"

# Start 'lemonbar' with a low priority. 
# - 'lemonbar' will be killed when status is killed.
echo "Starting lemonbar..." 1>&2
nice -19 $lemonbar_cmd $lemonbar_args -f "$STATUSBAR_FONT" < "$STATUS_FIFO_PATH"

# Start new process.
#nice status 2>/dev/null | lemonbar -f "$STATUSBAR_FONT" 

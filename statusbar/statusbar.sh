#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.07.2017 [dd.mm.yyyy]
# File: statusbar.sh
# Description: 
#   Starts and runs the statusline generator status
#   and pipes it's output into 'lemonbar'.
# Dependencies: status, lemonbar

### Setup
if [ -z "$FONTSIZE" ]; then
    case $# in
        0) FONTSIZE="23";;
        *) FONTSIZE="$1";;
    esac
fi

if [ -z "$FONT_SIZE_FILE" ]; then
	FONT_SIZE_FILE="/tmp/fontsize"
fi

if [ -z "$STATUS_PIPE_FILE" ]; then
	STATUS_FIFO_PATH="/tmp/status.pipe"
fi

if [ -z "$STATUSBAR_FONT" ]; then
	STATUSBAR_FONT="xft:Source Code Pro:pixelsize=$FONTSIZE:antialias=true"
fi

if [ -z "$STATUS_PID_FILE" ]; then
    STATUS_PID_FILE="/tmp/status_pid"
fi

### Main
echo "FONT_SIZE_FILE=$FONT_SIZE_FILE"
echo "FONTSIZE=$FONTSIZE"

# Save font size (used by other scripts).
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
status 2>/dev/null > "$STATUS_FIFO_PATH" &
status_pid="$!"
renice 19 -p "$status_pid"

# Write pid to file.
echo "$status_pid" > "$STATUS_PID_FILE"

# Start 'lemonbar' with a low priority. 
# - 'lemonbar' will be killed when status is killed.
nice -19 lemonbar -f "$STATUSBAR_FONT" < "$STATUS_FIFO_PATH"

# Start new process.
#nice status 2>/dev/null | lemonbar -f "$STATUSBAR_FONT" 

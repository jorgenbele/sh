#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.07.2017 [dd.mm.yyyy]
# Modified: 13.11.2017 [dd.mm.yyyy]
# File: statusbar.sh
# Description: 
#   Starts and runs the statusline generator status
#   and pipes it's output into 'lemonbar'.
# Dependencies: status, lemonbar

### Setup
# Setup font size file for restore and save.
[ -z "$FONT_SIZE_FILE" ] && FONT_SIZE_FILE="/tmp/fontsize"
# Try to set fontsize from argument.
[ -z "$FONTSIZE" ] && [ "$1" -gt 0 ] && FONTSIZE="$1"
# Try to load from font size file if no font size is already specified.
if [ -z "$FONTSIZE" ]; then
    FONTSIZE="$(cat $FONT_SIZE_FILE)"
    if [ "$FONTSIZE" -le 0 ]; then
        unset FONTSIZE
    fi
fi

# If loading from font size file failed, set to default.
[ -z "$FONTSIZE" ] && FONTSIZE="23"
# Setup pipe file.
[ -z "$STATUS_PIPE_FILE" ] && STATUS_FIFO_PATH="/tmp/status.pipe"
# Setup font.
if [ -z "$STATUSBAR_FONT" ]; then
	STATUSBAR_FONT="Source Code Pro:pixelsize=$FONTSIZE:antialias=true"
fi
# Setup pid file.
[ -z "$STATUS_PID_FILE" ] && STATUS_PID_FILE="/tmp/status_pid"

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
#status 2>/dev/null > "$STATUS_FIFO_PATH" &
status > "$STATUS_FIFO_PATH" &
status_pid="$!"
#renice 19 -p "$status_pid"

# Write pid to file.
echo "$status_pid" > "$STATUS_PID_FILE"

# Start 'lemonbar' with a low priority. 
# - 'lemonbar' will be killed when status is killed.
nice -19 lemonbar -f "$STATUSBAR_FONT" < "$STATUS_FIFO_PATH"

# Start new process.
#nice status 2>/dev/null | lemonbar -f "$STATUSBAR_FONT" 

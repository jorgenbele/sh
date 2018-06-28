#!/bin/sh

### Setup
case $# in
    0) FONTSIZE="25";;
    *) FONTSIZE="$1";;
esac

if [ "$FONT_SIZE_FILE" = "" ]; then
	FONT_SIZE_FILE="/tmp/fontsize"
fi

if [ "$BIN_PATH" = "" ]; then
	BIN_PATH="$HOME/bin"
fi

if [ "$STATUSBAR_FONT" = "" ]; then
	STATUSBAR_FONT="xft:Source Code Pro:pixelsize=$FONTSIZE:antialias=true"
fi

### Main
echo BIN_PATH="$BIN_PATH"
echo FONT_SIZE_FILE="$FONT_SIZE_FILE"
echo "FONTSIZE=$FONTSIZE"

# spawn new process
$BIN_PATH/statusbar.py | $BIN_PATH/lemonbar -f "$STATUSBAR_FONT" -p &2>/dev/null &

# save font size (used by other scripts)
echo "$FONTSIZE" > "$FONT_SIZE_FILE"

#!/bin/sh
# File: multi-monitor-toggle.sh
# Author: Jørgen Bele Reinfjell
# Date: 04.07.2018 [dd.mm.yyyy]

#!import commands.*

dependencies="xrandr"
DESCRIPTION_TEXT="Toggles between the multi-monitor- and the single-monitor setup."

default_setup "$@"

TOGGLE_FILE="/tmp/using-multi-monitors"

if [ "$(cat $TOGGLE_FILE)" = "1" ]; then
	echo "Disabling multi monitors"
	xrandr --dpi 120 --output eDP1 --mode 2560x1440 \
		--output DP1 --off \
		--output HDMI2 --off
	echo "0" > $TOGGLE_FILE
else
	echo "Enabling multi monitors"
	xrandr --dpi 80 --output eDP1 --mode 1920x1080 \
		--output DP1 --right-of eDP1 --primary --mode 2560x1440 \
		--output HDMI2 --right-of DP1 --mode 1920x1080
	echo "1" > $TOGGLE_FILE
fi


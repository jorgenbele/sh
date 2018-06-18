#!/bin/sh
# File: rofi-locate.sh
# From: https://github.com/gotbletu/shownotes/blob/master/rofi_locate.md
# Author: gotbletu
# Modified: Jørgen Bele Reinfjell
# Modification date: 04.03.2018 [dd.mm.yyyy]
locate home | rofi -threads 0 -width 100 -dmenu -i -p "locate" | xargs -r -0 xdg-open


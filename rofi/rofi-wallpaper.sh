#!/bin/sh
# File: rofi-wallpaper.sh
# From: https://github.com/gotbletu/shownotes/blob/master/rofi_locate.md
# Author: gotbletu
# Modified: Jørgen Bele Reinfjell
# Modification date: 04.03.2018 [dd.mm.yyyy]
#!import commands.*
dependencies="rofi locate feh"
default_opts "$@"

set_wallpaper() {
    cp "$1" "$HOME/.wallpaper"

    # set wallpaper
    feh --bg-fill "$HOME/.wallpaper" --no-fehbg
}

wallpaper=$(locate $HOME/usr/pics/walls | rofi -threads 0 -dmenu -i -p "wallpaper" | head -1)
set_wallpaper "$wallpaper"

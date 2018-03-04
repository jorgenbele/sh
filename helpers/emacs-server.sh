#!/bin/sh
[ -z "$1" ] && t="default" || t="$1"
if ! pgrep -f "emacs --daemon=$t"; then 
    emacs "--daemon=$t" # start emacs in daemon mode using socket "$t"
fi

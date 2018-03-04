#!/bin/sh
if [ -z "$1" ]; then
    t="default"
else
    t="$1"
    shift 1
fi


emacs-server "$t" # start a new emacs daemon if needed with the socket "$t" 

if [ -z "$NO_WINDOW" ]; then
    emacsclient -s "$t" -c $@
else
    emacsclient -s "$t" $@
fi

#!/bin/sh
# Author: Jørgen Bele Reinfjell
# File: commands.sh
# Description: 
#   A collection of useful commands in the form of shell script functions.
# TODO: Actually add some useful functions...

log() {
    echo "$@" 1>&2
}

cmd_exists() {
    command -v "$1"
}

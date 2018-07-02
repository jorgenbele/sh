#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2015 [dd.mm.yyyy]
# File: beet_cue_split_import.sh
# Description:
#   Splits a flac '.cue' file into .flac files, tags 
#   them and then imports them into your beets library.
# Dependencies: beet, cuetag.sh, shnsplit 
#       (cuetools useually comes with cuetag and shnsplit)
#!import commands.*
dependencies="beet cuetag.sh shnsplit"
USAGE_TEXT="CUESHEET FLAC_FILE"
default_setup "$@"

if [ "$1" = "" ] || [ "$2" = "" ]; then
    default_usage
    exit 1
fi

# split files
splitdir="$(dirname "$2")/splits"
verbose mkdir "$splitdir"
mkdir "$splitdir"
verbose shnsplit -d "$splitdir" -f "$1" -o flac "$2" 
shnsplit -d "$splitdir" -f "$1" -o flac "$2" 

# tag files 
log "Tagging files.."
verbose cuetag.sh "$1" "$splitdir"/*.flac
cuetag.sh "$1" "$splitdir"/*.flac

log "Importing..."
verbose beet import "$splitdir"
beet import "$splitdir"

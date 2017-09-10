#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2015 [dd.mm.yyyy]
# File: beet_cue_split_import.sh
# Description:
#   Splits a flac '.cue' file into .flac files, tags 
#   them and then imports them into your beets library.
# Dependencies: beet, cuetag.sh, shnsplit 
#       (cuetools useually comes with cuetag and shnsplit)

if [ "$1" = "" ] || [ "$2" = "" ]; then
    echo "Usage: $0 CUESHEET FLAC_FILE"
    exit 1
fi

# split files
splitdir="$(dirname "$2")/splits"
mkdir "$splitdir"
shnsplit -d "$splitdir" -f "$1" -o flac "$2" 

# tag files 
echo "tagging..."

cuetag.sh "$1" "$splitdir"/*.flac

echo "importing..."
beet import "$splitdir"

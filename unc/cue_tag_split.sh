#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2015 [dd.mm.yyyy]
# File: cue_tag_split.sh
# Description:  Splits a flac '.cue' file into .flac files and tags them.
# Dependencies: cuetag.sh, shnsplit 
#       (cuetools useually comes with cuetag and shnsplit)
#   

if [ "$1" = "" ] || [ "$2" = "" ]; then
    echo "Usage: $0 CUESHEET FLAC_FILE"
    exit 1
fi

# split files
splitdir="$(dirname "$2")/splits"
mkdir "$splitdir"
shnsplit -d "$splitdir" -f "$1" -o flac "$2" 

# tag files 
echo "tagging"

cuetag.sh "$1" "$splitdir"/*.flac
exit

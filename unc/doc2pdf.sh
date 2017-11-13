#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2015 [dd.mm.yyyy]
# File: beet_cue_split_import.sh
# Description: Converts a doc file to pdf script using pandoc and latex.
# Dependencies: pandoc, latex  

file="$1"
out="$2"

if [ "$file" = "" ]; then
    echo "Usage: "$0" FILE [out]"
    exit 1
else
   if [ "$out" = "" ]; then
       out="$file.pdf"
   else 
       out="$out"
   fi
   pandoc -t latex -o "$out" "$file"
fi

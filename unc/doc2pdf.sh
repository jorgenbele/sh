#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2015 [dd.mm.yyyy]
# File: beet_cue_split_import.sh
# Description: Converts a doc file to pdf script using pandoc and latex.
# Dependencies: pandoc, latex  
dependencies="pandoc"

#!import commands.*
USAGE_TEXT="FILE [OUT]"
default_setup "$@"

file="$1"
out="$2"

if [ "$file" = "" ]; then
    default_usage
    exit 1
else
   if [ "$out" = "" ]; then
       out="$file.pdf"
   else 
       out="$out"
   fi
   pandoc -t latex -o "$out" "$file"
fi

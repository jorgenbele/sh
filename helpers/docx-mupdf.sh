#!/bin/sh
# Author: Jørgen Bele Reinfjell
# Date: 20.11.2017 [dd.mm.yyyy]
# File: docx-mupdf.sh
# Description: 
#   Converts docx files to pdf using the 'docx2pdf' script, ands opens in mupdf.
# Dependencies: docx2pdf, mupdf

#!import commands.has_commands.
#!import commands.check_deps
#!import commands.logf
#!import commands.log
#!import commands.verbose

dependencies="docx2pdf mupdf"

VERBOSE=false

run() {
    of="$(docx2pdf -l - "$1")"
    if [ "$?" -eq 0 ]; then
        printf "Opening: %s" "$of\n"
        mupdf "$of"
    else
        logf "Conversion of \"%s\" failed!\n" "$of"
    fi
}

usage() {
    echo "Usage: $0 [-dh] [FILE ...]"
}

opts="dhv"
while getopts "$opts" arg; do
    case "$arg" in
        'v') VERBOSE=true;              ;;
    esac
done
OPTIND=1

while getopts "$opts" arg; do
    case "$arg" in
        'd') check_deps; exit "$?";     ;;
        'h') usage; exit 0;             ;;
        '?') log "Internal error: $arg" ;;
    esac
done

if [ "$#" = 0 ]; then
    usage
    exit 1
fi

if [ "$#" -gt 1 ]; then
    # iterate over all arguments, and run in 
    # seperate processes in the background
    while [ -n "$1" ]; do
        run "$1" &
    done
else
    # only run one instance, in the foreground
    run "$1" &
fi

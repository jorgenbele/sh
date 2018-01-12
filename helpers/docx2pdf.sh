#!/bin/sh
# Author: Jørgen Bele Reinfjell
# Date: 13.11.2017 [dd.mm.yyyy]
# File: docx2pdf.sh
# Description: Converts docx files to pdf using pandoc.
# Dependencies: pandoc
verbose() {
    [ -n "$VERBOSE" ] && echo "$@"
}

stripext() {
    echo "$@" | sed 's~\..*$~~g'
}

conv() {
    of="$(stripext "$@").pdf"
    pandoc -o "$of" -f docx "$@"
    ret="$?"
    if $LIST && [ "$ret" -eq 0 ]; then
        echo "$of"
    fi
    return "$?"
}

usage() {
    echo "Usage: $0 [-hv]"
    echo "      -h            display this help and exit"
    echo "      -l            enable listing of output file name"
    echo "      -v            enable verbose output"
}

# parse args
[ "$#" -eq 0 ] && usage 1>%2 # no arguments, display usage

OPTS="hvl"
while getopts "$OPTS" arg; do
    case "$arg" in
        'v')     VERBOSE=true; continue ;;
        'h')     usage;        exit 0   ;;
        'l')     LIST=true;    continue ;;
        '-')     break                  ;;
        *)       echo "Internal error: $arg" 1>&2;  exit 1 ;;
    esac
done

shift $(($OPTIND-1))

[ -z "$1" ] && verbose "Finished, nothing to do." && exit 0

failed=0
while [ -n "$1" ]; do
    file="$1"
    verbose "Converting: \"$file\"..."
    conv "$file"
    [ "$?" -ne 0 ] && failed="$(($failed+1))"
    shift 1
done

if [ "$failed" -gt 0 ]; then
    echo "Finished with $failed errors." 1>&2
    exit 1
fi

verbose "Finished."
exit 0

#!/bin/sh
# Author: Jørgen Bele Reinfjell
# Date: 13.11.2017 [dd.mm.yyyy]
# File: docx2pdf.sh
# Description: Converts docx files to pdf using pandoc.
# Dependencies: pandoc

#!import commands.verbose
#!import commands.log
#!import commands.has_commands
#!import commands.check_deps
#!import commands.stripext

dependencies="pandoc"

VERBOSE=false

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
    echo "  -h  Display this help and exit"
    echo "  -l  Enable listing of output file name"
    echo "  -v  Enable verbose output"
    echo "  -d  Exits with no error code if all dependencies are set up"
}

# parse args
[ "$#" -eq 0 ] && usage 1>&2 # no arguments, display usage

OPTS="dhvl"
while getopts "$OPTS" arg; do
    case "$arg" in
        'v') VERBOSE=true; continue; ;;
    esac
done
OPTIND=1

while getopts "$OPTS" arg; do
    case "$arg" in
        'd') check_deps; exit "$?"; ;;
        'h') usage; exit 0;         ;;
        'l') LIST=true; continue;   ;;
        '-') break;                 ;;
        '?') log "Internal error: $arg"; exit 1; ;;
    esac
done

shift $(($OPTIND-1))

[ -z "$1" ] && verbose "Finished, nothing to do." && exit 0

failed=0
while [ -n "$1" ]; do
    file="$1"
    verbose "Converting: \"$file\"..."
    conv "$file"
    [ "$?" -ne 0 ] && failed="$(($failed+1))"
    shift 1
done

if [ "$failed" -gt 0 ]; then
    log "Finished with $failed errors." 1>&2
    exit 1
fi

verbose "Finished."
exit 0

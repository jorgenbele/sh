#!/bin/sh
# File: torrent.sh
# Date: 06.05.2018 [dd.mm.yyyy]
# Author: Jørgen Bele Reinfjell

DEST_DIR="$HOME/dls/torrent"
MAGNET_FILE="magnet.txt"

VERBOSE=false
METADATA=false
METADATA_FILE="meta.json"
OMDB_API_KEY=""

usage() {
    printf "Usage: %s [-hlv] [-a NAME MAGNET] [-[cdr] NAME]\n" "$0"
    printf   "    -h|help                 display this message and quit\n"
    printf   "    -v|verbose              toggle verbose output\n"
    printf   "    -m|metadata             save metadata from OMDB\n"
    printf   "    -a|add      NAME MAGNET add a new torrent\n"
    printf   "    -c|continue NAME        continue torrenting\n"
    printf   "    -d|visit    NAME        change to a torrents dir\n"
    printf   "    -l|list                 list all torrents\n"
    printf   "    -r|remove   NAME        remove torrent (all data) of torrent by name\n"
}

# sets up directories
setup() {
    if ! [ -d "$DEST_DIR" ]; then 
        mkdir -p "$DEST_DIR" || echo "Unable to create dest parent directory $DEST_DIR" && exit 1
    fi
}

# stdin - input text
snakecase_inp() {
    # Inspired from https://stackoverflow.com/questions/4569825/sed-one-liner-to-convert-all-uppercase-to-lowercase
    # Submitted by user: magnetar 2011, edited by echristopherson 2015.
    tr '[:upper:] ' '[:lower:]_' 
}

# $1 - name
remove() {
    # remove directory if it exists
    local dir="$DEST_DIR/$(echo "$1" | snakecase_inp)"

    if ! [ -d "$dir" ]; then
        echo "Torrent directory: \"$dir\" does not exist" 1>&2
        exit 1
    fi

    $VERBOSE && echo "Removing directory: \"$dir\" using: rm -r \"$dir\"" 1>&2
    #rm -r "$dir"
}

# $1 - name
metadata() {
    # TODO
    echo "$1"
}

# $1 - name
write_metadata() {
        local metadir="$dir/$METADATA_FILE"
        $VERBOSE && echo "Searching for metadata using OMDB for: \"$1\"" 1>&2
        local meta="$(metadata "$1")"
        if [ "$?" != 0 ]; then
            $VERBOSE && echo "Failed to get metadata for: \"$1\"" 1>&2
        fi
        echo "$meta" > "$METADATA_FILE"
        $VERBOSE && echo "Wrote metadata file: \"$1\"" 1>&2
}

# $1 - name
# $2 - magnet link
add() {
    # make sure it does not already exist
    local dir="$DEST_DIR/$(echo "$1" | snakecase_inp)"
    $VERBOSE && echo "Creating directory: \"$dir\"" 1>&2

    if ! [ -d "$dir" ] && ! mkdir -p "$dir"; then
        echo "Failed to create torrent directory: \"$dir\"" 1>&2
        exit 1
    fi

    $VERBOSE && echo "Saving magnet link as: \"$dir/$MAGNET_FILE\"" 1>&2
    echo "$2" > "$dir/$MAGNET_FILE"

    if "$METADATA"; then
        write_metadata "$1" &
    fi

    $VERBOSE && echo "Starting aria2c in directory: \"$dir\"" 1>&2
    $VERBOSE && echo "aria2c -d "$dir" "$2"" 1>&2
    aria2c -d "$dir" "$2"
}

# $1 - name
continue_() {
    # make sure it does not already exist
    local dir="$DEST_DIR/$(echo "$1" | snakecase_inp)"
    $VERBOSE && echo "Continuing: \"$1\"" 1>&2

    local magnet="$(cat "$dir/$MAGNET_FILE")"
    $VERBOSE && printf "Magnet link: \n%s\n" "$magnet" 1>&2

    $VERBOSE && echo "(continuing) Starting aria2c in directory: \"$dir\"" 1>&2
    $VERBOSE && echo "aria2c -d "$dir" "$2"" 1>&2
    aria2c --continue -d "$dir" "$2"
}

# $1 - name
visit() {
    # make sure it does not already exist
    local dir="$DEST_DIR/$(echo "$1" | snakecase_inp)"
    $VERBOSE && echo "Visiting: \"$dir\"" 1>&2
    cd "$dir"
    sh
}

list() {
    ls "$DEST_DIR"
}

##########
## main ##
##########
if [ "$#" = 0 ]; then
    usage && exit 1
fi

setup

OPTS=""
while true; do
    case "$1" in
        '-a'|'add')    
            add "$2" "$3";
            shift 3
            ;;
        '-c'|'continue')    
            # continue
            continue_ "$2";
            shift 2;
            ;;
        '-d'|'visit')    
            # visit
            visit "$2";
            shift 2;
            ;;
        '-h'|'help')    
            # help
            usage;
            shift 1;
            exit 0
            ;;
        '-l'|'list')    
            # list
            list;
            shift 1;
            exit 0
            ;;
        '-m'|'metadata')    
            # metadata
            METADATA=true;
            shift 1;
            ;;
        '-r'|'remove')    
            # remove
            remove "$2";
            shift 2;
            ;;
        '-v')    
            # verbose
            VERBOSE=true;
            shift 1
            ;;
        '--') 
            # treat all remaining arguments as non-flags
            shift 1;
            break
            ;;
        *) 
            # unsupported
            echo "Internal error: $1" 1>&2;
            exit 1
            ;;
    esac
done

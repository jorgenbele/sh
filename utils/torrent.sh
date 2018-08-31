#!/bin/sh
# File: torrent.sh
# Date: 06.05.2018 [dd.mm.yyyy]
# Author: Jørgen Bele Reinfjell

#!import commands.verbose
#!import commands.verbosef
#!import commands.log
#!import commands.logf
#!import commands.has_commands
#!import commands.check_deps

dependencies="aria2c"

# Use environment variables if set.
[ -z "$DEST_DIR"      ] && DEST_DIR="$HOME/dls/torrent"
[ -z "$MAGNET_FILE"   ] && MAGNET_FILE="magnet.txt"
[ -z "$METADATA"      ] && METADATA=false
[ -z "$METADATA_FILE" ] && METADATA_FILE="meta.json"
[ -z "$OMDB_API_KEY"  ] && OMDB_API_KEY=""
[ -z "$VERBOSE"       ] && VERBOSE=false
[ -z "$TORRENT"       ] && TORRENT=false

HAS_SETUP=false

usage() {
    echo "Usage: $0 [-hlv] [MODE PARAMS]"
    echo "  -h  Display this message and quit"
    echo "  -v  Toggle verbose output"
    echo "  -m  Save metadata from OMDB"
    echo "  -t  Torrent (calls 1337x)"
    echo "  -d  Exits with no error code if all dependencies are set up"
    echo
    echo "MODE PARAMS can be one of the following"
    echo "  -a|add      NAME MAGNET  Add a new torrent"
    echo "  -c|continue NAME         Continue torrenting"
    echo "  -V|visit    NAME         Change to a torrents dir"
    echo "  -l|list                  List all torrents"
    echo "  -r|remove   NAME         Remove torrent (all data) of torrent by name"
    echo
    echo "Dependencies: $dependencies"
    echo
    echo "Examples:"
    echo "$0 -vV some_torrent_name"
    echo "$0 -v visit some_torrent_name"
}

# setup(): Creates the necessary directories needed to use this script.
# sets up directories
setup() {
    if ! [ -d "$DEST_DIR" ]; then 
        if ! mkdir -p "$DEST_DIR"; then
            log "Unable to create dest parent directory: $DEST_DIR"
            exit 1
        fi
        log "Created dest parent directory: $DEST_DIR"
    fi
}

# setup_if_needed(): Make sure that setup() is only called once. 
setup_if_needed() {
    if ! "$HAS_SETUP"; then
        setup
    fi
}

# snakecase_inp(): Converts a string from uppercase to
#                  and lowercase and replaces spaces with underscores.
# stdin - input text
snakecase_inp() {
    # Inspired from https://stackoverflow.com/questions/4569825/sed-one-liner-to-convert-all-uppercase-to-lowercase
    # Submitted by user: magnetar 2011, edited by echristopherson 2015.
    tr '[:upper:] ' '[:lower:]_' 
}

# remove(): Removes a torrent and its related directories and files.
# $1 - name
remove() {
    setup_if_needed
    destdir="$DEST_DIR/$(echo "$1" | snakecase_inp)"

    if ! [ -d "$destdir" ]; then
        log "Torrent directory: \"$destdir\" does not exist"
        exit 1
    fi

    verbose "Removing directory: \"$destdir\" using: rm -r \"$destdir\""
    #rm -r "$destdir"
}

# NOTE: Not implemented.
# $1 - name
metadata() {
    # TODO
    echo "$1"
}

# NOTE: Not implemented.. 
# write_metadata(): Write metadata fetched from OMDB for the given torrent.
# $1 - name
write_metadata() {
    setup_if_needed
    metadir="$destdir/$METADATA_FILE"
    verbose "Searching for metadata using OMDB for: \"%s\"" "$1"
    meta="$(metadata "$1")"
    if [ "$?" != 0 ]; then
        verbose "Failed to get metadata for: \"$1\""
    fi
    echo "$meta" > "$METADATA_FILE"
    verbose "Wrote metadata file: \"$1\""
}

# add(): Adds a torrent by name and magnet link.
# $1 - name
# $2 - magnet link (only if $TORRENT is false)
add() {
    setup_if_needed
    destdir="$DEST_DIR/$(echo "$1" | snakecase_inp)"
    magnet_link="$2"
    verbosef "Creating directory: \"%s\"\n" "$destdir"

    if ! [ -d "$destdir" ] && ! mkdir -p "$destdir"; then
        log "Failed to create torrent directory: \"%s\"" "$destdir"
        exit 1
    fi

    if "$TORRENT"; then
        verbosef "Starting 1337x client: 1337x -s -m search \"%s\"\n" "$1"
        magnet_link="$(1337x -s -m search "$1")"
    fi

    verbosef "Saving magnet link as: \"%s\"\n" "$destdir/$MAGNET_FILE"
    echo "$magnet_link" > "$destdir/$MAGNET_FILE"

    if "$METADATA"; then
        write_metadata "$1" &
    fi

    verbose "Starting aria2c in directory: \"$destdir\""
    verbose "aria2c -d "$destdir" "$maget_link""
    aria2c -d "$destdir" "$magnet_link"
}

# continue_(): Continues a torrent by name.
# $1 - name
continue_() {
    setup_if_needed
    destdir="$DEST_DIR/$(echo "$1" | snakecase_inp)"
    verbosef "Continuing: \"%s\"\n" "$1"

    magnet="$(cat "$destdir/$MAGNET_FILE")"
    verbosef "Magnet link: \n%s\n" "$magnet"

    verbosef "(continuing) Starting aria2c in directory: \"%s\"\n" "$destdir"
    verbosef "aria2c --continue -d \"%s\" \"%s\"\n" "$destdir" "$2"
    aria2c --continue -d "$destdir" "$2"
}

# visit(): Spawns a subshell in the desired torrents directory.
# $1 - name
visit() {
    setup_if_needed
    destdir="$(echo $DEST_DIR/*$(echo "$1" | snakecase_inp)*)"
    verbosef "Visiting: \"%s\"\n" "$destdir"
    env -C "$destdir" "$SHELL"
}

list() {
    #ls -Alh "$DEST_DIR" | tail -n 1
    verbose du -chsS "$DEST_DIR/"*
    du -chsS "$DEST_DIR/"*
}

##########
## main ##
##########
if [ "$#" = 0 ]; then
    usage && exit 1
fi

# NOTE: I chose to do the parsing in two parts due to the
# need to enable toggles before execution of any commands.
# This means that the -v (verbose) toggle is position independent.
opts="hmvdatVlrc"
while getopts "$opts" arg; do
    case "$arg" in
        'm') METADATA=true; ;;
        'v') VERBOSE=true;  ;;
        't') TORRENT=true   ;;
    esac
done
OPTIND=1

while getopts "$opts" arg; do
    case "$arg" in
        'h') usage; exit 0; ;;
        'd') check_deps; exit; "$?" ;;
        'a') MODE='add'      ;;
        'V') MODE='visit'    ;;
        'l') MODE='list'     ;;
        'r') MODE='remove'   ;;
        'c') MODE='continue' ;;
        '?') log "Unknown option: $arg. Quitting."; exit 3 ;;
    esac
done

shift "$(($OPTIND-1))"

# Optionally one can specify the mode using a long-hand
# positional argument following all toggles.
if [ -z "$MODE" ]; then
    if [ -z "$1" ]; then
        usage; exit 1;
    else
        verbose "No mode provided by flags. Using $1."
        MODE="$1"
        shift 1
    fi
fi

# Handle list on its own since it does not
# need a torrent name.
case "$MODE" in
    l*)
        list
        exit "$?"
        ;;
esac

nameopt="$1"
#magnetopt="$2"
shift 1
rest="$@"

if [ -z "$nameopt" ]; then
    log "No torrent name provided. Quitting."
    exit 1
fi

case "$MODE" in
    a*)
        #if [ -z "$magnetopt" ]; then
        #    log "No magnet link provided. Quitting."
        #    exit 2
        #fi
        if ! "$TORRENT" && [ -z "$rest" ]; then
            log "No magnet link provided. Quitting."
            exit 2
        fi
        #add       "$nameopt" "$magnetopt";
        add       "$nameopt" "$rest";
        ;;
    v*) visit     "$nameopt"; ;;
    r*) remove    "$nameopt"; ;;
    c*) continue_ "$nameopt"; ;;
esac

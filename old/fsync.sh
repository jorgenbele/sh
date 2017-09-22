#!/bin/sh
# Author: Jørgen Bele Reinfjell
# Date: 17.09.2017 [dd.mm.yyyy]
# File: fsync.sh
# Description: Simple script using rsync to push, pull and sync directories and files.

#RSYNC_ARGS="rsync --verbose --progress --archive --recursive --update -links --preallocate --one-file-system --delete-after --delay-updates --compress --skip-compress=\".iso .img .mp3 .mp4 .jpg .png\" --itemize-changes -b --backup-dir=\"$HOME/.rsync_bak\" --suffix=\"~\""
RSYNC_ARGS="--verbose --progress --archive --recursive --update -links --preallocate --one-file-system --delete-after --delay-updates --compress --itemize-changes -b --backup-dir=\"$HOME/.rsync_bak\" --suffix=\"~\""

find_files_list() {
    FILES_LISTS="$HOME/.rsync.flist .rsync.flist"
    for files_list in $FILES_LISTS; do
        #echo "Checking: $files_list"
        [ -f "$files_list" ] && FILES_LIST="$files_list" && echo "Using files list: $FILES_LIST" && return 0
    done
    echo "Found no files list" 1>&2
    return 1
}

find_exclude_list() {
    FILES_X_LISTS="$HOME/.rsync.xlist $PWD/.rsync.xlist"
    for files_x_list in "$FILES_X_LISTS"; do
        [ -f "$files_x_list" ] && EXCLUDE_FILES_LIST="$files_x_list" &&  echo "Using exclude files list: $EXCLUDE_FILES_LIST" && return 0
    done
    echo "Found no exclude list" 1>&2
    return 1
}

push() {
    for remote in "$REMOTES"; do
        echo "===================================================" 1>&2
        echo "Pushing to remote: $remote" 1>&2
        cat "$FILES_LIST" 1>&2
        echo "Running command: rsync $RSYNC_ARGS \"$remote\" $DIRS --files-from=\"$FILES_LIST\""
        rsync $RSYNC_ARGS --files-from="$FILES_LIST" "$remote"
        echo "rsync returned: $?" 1>&2
        echo "===================================================" 1>&2
    done
}

pull() {
    for remote in "$REMOTES"; do
        echo "===================================================" 1>&2
        echo "Pulling from remote: $remote" 1>&2
        cat "$FILES_LST" 1>&2

        echo "Running command: rsync $RSYNC_ARGS \"$remote\"  --files-from=\"$FILES_LIST\" $DIRS"
        rsync $RSYNC_ARGS --files-from="$FILES_LIST" "$remote"
        echo "rsync returned: $?" 1>&2
        echo "===================================================" 1>&2
    done
}

usage() {
    echo "Usage: $0 [-h] [-f FILES_LIST] [-x EXCLUDE_LIST] [-r REMOTE] [-m REMOTES_LIST] [REMOTE] [push|pull|sync] ..."
    echo "      -h              show this help message and quit"
    echo "      -f FILES_LIST   set the files list"
    echo "      -x EXCLUDE_LIST set the exclude files list"
    echo "      -m REMOTES_LIST set the remotes file list, allows pulling and pushing to and from multiple remotes"
}


OPTS="hf:x:r:m:"
while getopts "$OPTS" arg; do
    case "$arg" in
        'f')     FILES_LIST="$OPTARG";         continue ;;
        'x')     EXCLUDE_FILES_LIST="$OPTARG"; continue ;;
        'm')     REMOTES_LIST="$OPTARG";       continue ;;
        'r')     REMOTE="$OPTARG";             continue ;;
        'h')     usage; exit 0 ;;
        '-')     break ;;
        *)       echo "Internal error: $arg" 1>&2;  exit 1 ;;
    esac
done
shift $(($OPTIND - 1)) # shift to non-parsed args


# if not REMOTE or REMOTES_LIST is specified, treat the next argument as
if [ -n "$REMOTE" ]; then
    REMOTES="$REMOTE"
elif [ -n "$REMOTES_LIST" ]; then
    REMOTES="$(cat \"$REMOTES_LIST\")"
else
    [ -z "$1" ] && echo "No remote selected" 1>&2 && usage && exit 1
    REMOTES="$1"
    shift 1
fi

# try to find exclude_list if none was provided
[ -z "$EXCLUDE_FILES_LIST" ] && find_exclude_list
# try to find filse_list if none was provided
if [ -z "$FILES_LIST" ]; then
    find_files_list || exit  "$?" # quit on error
fi

echo "\$@=$@"

# treat rest of args as operations, do operations
while [ -n "$1" ]; do
    case "$1" in
        'pull')  pull ;;
        'push')  push ;;
        'sync') pull; push ;;
        *) echo "Unknown operation: $1" 1>&2; exit 1;;
    esac
    shift 1
done

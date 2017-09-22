#!/bin/sh
#RSYNC_ARGS="--verbose --progress --archive --recursive --update --links --preallocate --one-file-system --delete-after --delay-updates --compress --itemize-changes --backup --backup-dir=\"$HOME/.rsync_bak\" --suffix=\"~\""
RSYNC_ARGS="-vaulcb --backup-dir=$HOME/.rsync_bak --suffix=~$(date +%s) --progress"
CONFIRM_LARGE_FILES=true
LARGE_FILE_SIZE_BYTES=$((1024*1024*100)) # 100 MiB

OPERATION="$1"
REMOTE="$2"
shift 2
FPATHS="$@"

confirm_if_large_file() {
    fs_cmd="stat --printf %s $1"
    #perl_cmd="perl -e 'print((stat(\"$1\"))[7])'"
    #echo "perl_cmd:$perl_cmd"
    if [ "$2" = "push" ]; then
        #filesize=$($perl_cmd)
        filesize=$($fs_cmd)
    else
        #filesize=$(ssh "$REMOTE" $perl_cmd)
        filesize=$(ssh "$REMOTE" $fs_cmd)
    fi
    [ "$?" -ne "0" ] && echo "Failed to get size of file: $1" && return 2
    echo "filesize:$filesize"
    if [ "$filesize" -ge "$LARGE_FILE_SIZE_BYTES" ]; then
        printf "File %s is large - %d bytes.\nAre you sure you want to continue the operation on this file? [Y/n] " "$1" "$filesize"
        read -r inp
        echo "Read: $inp"
        case "$inp" in
            N*|n*)   echo "Skipping file: $1"; return 1 ;;
            Y*|y*|*) echo "Continuing with file: $1"; return 0 ;;
        esac
    fi
    return 0
}

pull() {
    echo rsync $RSYNC_ARGS "$REMOTE:\"$1\"" "$1"
    rsync $RSYNC_ARGS "$REMOTE:\"$1\"" "$1"
}

push() {
    echo rsync $RSYNC_ARGS "$1" "$REMOTE:$1"
    rsync $RSYNC_ARGS "$1" "$REMOTE:$1"
}

echo "OPERATION:$OPERATION REMOTE:$REMOTE FPATHS:$FPATHS"
case "$OPERATION" in
    'push') echo "== Pushing to $REMOTE ==" ;;
    'pull') echo "== Pulling from $REMOTE ==" ;;
    'syncing') echo "== Syncing with $REMOTE ==" ;;
esac

while [ -n "$1" ]; do
    confirm_if_large_file "$1" "$OPERATION"
    ret="$?"
    echo "$ret"
    [ "$ret" -eq "1" ] && shift 1 && continue
    ! [ "$ret" -eq "0" ] && exit 1

    case "$OPERATION" in
        'pull') pull "$1" ;;
        'push') push "$1" ;;
        'sync') pull "$1" ; push "$1" ;;
    esac
    shift 1
done

case "$OPERATION" in
    'push') echo "== Done pushing to $REMOTE ==" ;;
    'pull') echo "== Done pulling from $REMOTE ==" ;;
    'syncing') echo "== Done syncing with $REMOTE ==" ;;
esac

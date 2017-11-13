#!/bin/sh
#RSYNC_ARGS="--verbose --progress --archive --recursive --update --links --preallocate --one-file-system --delete-after --delay-updates --compress --itemize-changes --backup --backup-dir=\"$HOME/.rsync_bak\" --suffix=\"~\""
RSYNC_ARGS="-vaulb --backup-dir=$HOME/.rsync_bak --suffix=~$(date +%s) --progress"
CONFIRM_LARGE_FILES=true
LARGE_FILE_SIZE_BYTES=$((1024*1024*100)) # 100 MiB

OPERATION="$1"
REMOTE="$2"
shift 2
FPATHS="$@"

confirm_if_large_file() {
    perl_cmd="perl -e 'print((stat(\"$1\"))[7])'"
    echo "perl_cmd:$perl_cmd"
    if [ "$2" = "push" ]; then
        filesize=$($perl_cmd)
    else
        filesize=$(ssh "$REMOTE" $perl_cmd)
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
    # echo rsync $RSYNC_ARGS "$REMOTE:\"$1\"" "\"$1\""
    # rsync $RSYNC_ARGS "$REMOTE:\"$1\"" "\"$1\""
    echo rsync $RSYNC_ARGS "$REMOTE:\"$1\"" "$1"
    rsync $RSYNC_ARGS "$REMOTE:\"$1\"" "$1"
}

push() {
    # echo rsync $RSYNC_ARGS  "$1" "$REMOTE:\"$1\""
    # rsync $RSYNC_ARGS  "\"$1\"" "$REMOTE:\"$1\""
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
    # TODO: refactor
    isdir_cmd="test -d $1"
    if [ "$OPERATION" = "pull" ]; then
        isdir_cmd="ssh $REMOTE $isdir_cmd"
        #echo "Executing on remote server: $isdir_cmd"
    fi
    $isdir_cmd
    ret="$?"
    echo "Done!"
    if [ "$ret" -eq 0 ]; then
        echo "--File is a directory!--"
        find_cmd="find $1 -type f -print0"
        if [ "$OPERATION" = "pull" ]; then
            #echo "Executing on remote server: ssh $REMOTE $find_cmd"
            find_cmd="$(ssh $REMOTE $find_cmd)"
        else
            #echo "Executing on remote server: mkdir -p $1"
            ! ssh $REMOTE mkdir -p "$1" && echo "Failed to create directory on remote!" && exit 1
        fi

        #for file in "$files"; do
        # https://askubuntu.com/questions/343727/filenames-with-spaces-breaking-for-loop-find-command
        BIFS="$IFS"

        $find_cmd | while IFS= read -r -d '' file; do
            IFS="$BIFS"
            #echo "Doing file: '$file'"
            confirm_if_large_file "$file" "$OPERATION" <&1
            ret="$?"
            echo "$ret"
            [ "$ret" -eq "1" ] &&  continue
            ! [ "$ret" -eq "0" ] && break

            # make sure parent directory exists
            if [ "$OPERATION" = "push" ]; then
                #echo "Executing on remote server: mkdir -p $(dirname $file)"
                ssh $REMOTE mkdir -p "$(dirname $file)"
            else
                mkdir -p "$(dirname $file)"
            fi

            case "$OPERATION" in
                'pull') pull "$file" ;;
                'push') push "$file" ;;
                'sync') pull "$file" ; push "$file" ;;
            esac
        done
        shift 1
    else
        confirm_if_large_file "$1" "$OPERATION"
        ret="$?"
        echo "$ret"
        [ "$ret" -eq "1" ] && shift 1 && continue
        ! [ "$ret" -eq "0" ] && exit 1

        # make sure parent directory exists
        if [ "$OPERATION" = "push" ]; then
            #echo "Executing on remote server: mkdir -p $(dirname $1)"
            ssh $REMOTE mkdir -p "$(dirname $1)"
        else
            mkdir -p "$(dirname $1)"
        fi

        case "$OPERATION" in
            'pull') pull "$1" ;;
            'push') push "$1" ;;
            'sync') pull "$1" ; push "$1" ;;
        esac
        shift 1
    fi

done

case "$OPERATION" in
    'push') echo "== Done pushing to $REMOTE ==" ;;
    'pull') echo "== Done pulling from $REMOTE ==" ;;
    'syncing') echo "== Done syncing with $REMOTE ==" ;;
esac

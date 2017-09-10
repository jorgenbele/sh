#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 10.09.2017 [dd.mm.yyyy]
# File: notification.sh
# Description: Manages a notification status file by adding or removing keys.

# Stores the notification status as a pair of keys and values.
# The keys are used to remove parts of the notification status line.
[ -z "$CUSTOM_HOME" ] && CUSTOM_HOME="$HOME"
KEY_VAL_FILE="$CUSTOM_HOME/.not_kv" 
OUT_FILE="$CUSTOM_HOME/.not"

usage() {
    echo "Usage: $0 [-ghpvgx] [-sid VALUE] [-o OUTPUT]"
    echo "      -h  display this help and exit"
    echo "      -k  set key"
    echo "      -a  add message"
    echo "      -d  delete notification line element by key"
    echo "      -t  set the duration of the notification element"
}

is_number() {
    digits="$(echo "$1" | grep '^[0-9][0-9]*[\.]*[0-9]*$')"
    return "$?"
}

OPTS="hgk:a:d:t:"
while getopts "$OPTS" arg; do
    case "$arg" in
        'h')     usage; exit 0 ;;
        'k')     KEY="$OPTARG"; continue ;;
        'g')     MODE="get"; continue ;;
        'a')     MODE="add";  MESSAGE="$OPTARG"; continue ;; 
        'd')     MODE="delete"; KEY="$OPTARG"; continue ;;
        't')     DURATION="$OPTARG"; continue ;;
        '-')     break ;;
        *)       echo "Internal error: $arg" 1>&2; exit 1 ;;
    esac
done

case "$MODE" in
    'add') 
        ! [ -f "$KEY_VAL_FILE" ] && touch "$KEY_VAL_FILE"
        [ -z "$KEY" ] && KEY="$(date +"%s")" # use seconds since epoch as key
        # replace all instances of KEY in file or if none append a new line
        if grep "$KEY=" "$KEY_VAL_FILE"; then
            sed  -i "s/$KEY=.*$/$KEY=$MESSAGE/g" "$KEY_VAL_FILE"
        else
            echo "$KEY=$MESSAGE" >> "$KEY_VAL_FILE"
        fi
        chmod 666 "$KEY_VAL_FILE"
        ;;
    'delete') 
        [ -z "$KEY" ] && echo "A key ia required: set key using the -k field" && usage && exit 1 
        # delete all instances of KEY from file
        sed -i "/$KEY/d" "$KEY_VAL_FILE" 
        chmod 666 "$KEY_VAL_FILE"
        ;;
    'get'|*)
        ! [ -f "$KEY_VAL_FILE" ] && echo "No key_val file" && exit 0
        lines="$(sed "s/^.*=//g" < "$KEY_VAL_FILE")" # > "$OUT_FILE"
        #echo "$lines"
        BIFS="$IFS"
        IFS="$(printf '\t\n\"')"
        for l in $lines; do
            printf "[%s]" "$l"
        done
        IFS="$BIFS"
        printf "\n"
        exit 0
        ;;
esac

# generate new notification line file
case "$MODE" in
    'add'|'delete') 
        [ -f "$OUT_FILE" ] && rm "$OUT_FILE"
        ! [ -f "$KEY_VAL_FILE" ] && echo "No key_val file" && exit 0
        lines="$(sed "s/^.*=//g" < "$KEY_VAL_FILE")" # > "$OUT_FILE"
        BIFS="$IFS"
        IFS="$(printf '\t\n\"')"
        for l in $lines; do
            printf "[%s]" "$l" >> "$OUT_FILE"
        done
        IFS="$BIFS"

        # make the file rw for everyone
        chmod 666 "$OUT_FILE"
        ;;

esac

# sleep for duration then delete key using a recursive call to itself
if [ -n "$DURATION" ]; then
    sleep "$DURATION"
    "$0" -d "$KEY"
fi


#echo "KEY:\"$KEY\" MESSAGE:\"$MESSAGE\" MODE:\"$MODE\""
#cat "$KEY_VAL_FILE" | sed "br; a: /$KEY=$MESSAGE/a\\; r: s/^$KEY=.*$/$KEY=$MESSAGE/g; ta ; :e"
#sed  -i "s/$KEY=.*$/$KEY=$MESSAGE/g; te ; a$KEY=$MESSAGE\\" "$KEY_VAL_FILE"
#echo sed  -i \""s/$KEY=.*$/$KEY=$MESSAGE/g; t ; a$KEY=$MESSAGE\\\"" "$KEY_VAL_FILE"

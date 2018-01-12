#!/bin/sh
# Description: generates backup archives of a precompiled list of directories and files
# Author: Jørgen Bele Reinfjell
# Date: 19.09.2017 [dd.mm.yyyy]
# File: bak-gen.sh

[ -z "$HOSTNAME" ] && HOSTNAME="$(hostname)"

fextr=".tar.xz"
uextr="$(date +%Y_%m_%d_%s)"
fname="backup_${HOSTNAME}_${uextr}${fextr}"
#compr="tar -acJv -T - -f $fname --"
tar_cmd="tar -acv -T - --"
xz_cmd="xz -z -T 0 - "

# Newline separated list of dirs (the '/' postfix are needed)
DIRS="$HOME/src/
$HOME/bin/
$HOME/usr/docs/
$HOME/usr/vpn/
$HOME/.ecryptfs/
$HOME/.sec/
$HOME/.emacs.d/
$HOME/.zsh
$HOME/.vim/
$HOME/.xinitrc.d/
$HOME/.mpd/
$HOME/.config/
"

# Newline separated list of files
FILES="$HOME/.bashrc
$HOME/.bash_profile
$HOME/.zshrc
$HOME/.shrc
$HOME/.astylerc
$HOME/.profile
$HOME/.editrc
$HOME/.inputrc
$HOME/.emacs
$HOME/.spacemacs
$HOME/.vimrc
$HOME/.xinitrc
$HOME/.Xresources
$HOME/.Xdefaults
$HOME/.xbindkeys
$HOME/.tmux.conf
$HOME/note
"

if [ "$INTERACTIVE" ]; then
    tfile="$(mktemp)"
    echo "tfile=$tfile"
    [ -z "$tfile" ] && echo "mktemp failed!" 1>&2 && exit 1

    # Convert DIRS and FILES to nul-terminated strings, store in temp file (for use by du)
    # Source: https://unix.stackexchange.com/questions/102891/posix-compliant-way-to-work-with-a-list-of-filenames-possibly-with-whitespace
    set -f; IFS='
    '                             # turn off variable value expansion except for splitting at newlines
    for path in $FILES $DIRS; do
        set +f; unset IFS         # restore globbing and field splitting at all whitespace
        printf "%s\0" "$path" >> "$tfile" # write null terminated paths to temp file
    done
    set +f; unset IFS             # restore globbing again in case $INPUT was empty

    # Is interactive
    # Run sorted 'du' on the files, this makes it easier to determine if there is large unwanted files.
    printf "List files: [y/n]: "
    case "$inp" in
        "N*"|"n*")  ;;
        "Y*"|"y*"|*)
            # TODO: change out --files0-from with something else
            du -hac --files0-from="$tfile"  | sort -uh ;;
    esac
    rm "$tfile" # remove temp file

    printf "Continue backup [yes/no]: "
    read -r inp
    case "$inp" in
        "yes") ;;
        "no"|*) printf "Exiting.."; exit 0 ;;
    esac
fi


## Time
# tsec(): time in seconds since UNIX time epoch)
tsec() {
    date +"%s"
}

# difftime(time): converts the time difference between time $1 and now
difftime() {
    local time="$1"
    local now="$(tsec)"

    echo $(($now - $time))
}

# stohms(seconds): convert seconds to hh:mm:ss
stohms() {
    local ts="$1"

    local h="$(($ts/3600))"
    local m="$((($ts%3600)/60))"
    local s="$(($ts%60))"
    printf "%02d:%02d:%02d" "$h" "$m" "$s"
}

# Do backup
echo "$(date +%H:%M:%S) Starting: '[DIRS] [FILES] | $compr'"
stime="$(tsec)"
echo "$FILES" "$DIRS" | $tar_cmd | $xz_cmd > "$fname"
difft="$(difftime $stime)"
echo "$(date +%H:%M:%S) Finished! Took $difft seconds ($(stohms $difft))."

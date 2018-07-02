#!/bin/sh
# File: emount.sh
# Author: Jørgen Bele Reinfjell
# Date: xx.xx.2016 [dd.mm.yyyy] (estimate)
# Description: Script for mounting an ecryyptfs container.

#!import commands.*
dependencies="ecryptfs-insert-wrapped-passphrase-into-keyring mount.ecryptfs_private notification"
USAGE_TEXT="[CONTAINER]"
default_setup "$@"

if [ -z "$SECRET_DIR" ]; then
    if [ -n "$1" ]; then
        SECRET_DIR="$1"
    else
        SECRET_DIR="sec"
    fi
fi

success() {
    # write to statusline
    notification -k "emount:$SECRET_DIR" -a "ecryptfs: $SECRET_DIR" &
    echo "[SUCCESS]"
    exit 0
}

failure() {
    # write to statusline
    notification -t 10 -k "emount_failure" -a "ecryptfs: $SECRET_DIR failed" &
    echo "[FAILURE]"
    exit 1
}

# insert passphrase into keyring
ecryptfs-insert-wrapped-passphrase-into-keyring

# get mount dir
sec_mnt="$(awk '{print $2}' < "$HOME/.ecryptfs/$SECRET_DIR.conf")"

# make mount dir
mkdir -p "$sec_mnt"

# mount secret directory
printf "Mounting '$SECRET_DIR' to '$sec_mnt': "
mount.ecryptfs_private "$SECRET_DIR" && success || failure 


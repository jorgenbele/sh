#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2016 [dd.mm.yyyy]
# File: emount.sh
# Description: 
#   Decrypts and mounts the encrypted secret directory 
#   $HOME/.$SECRET_DIR to $HOME/$SECRET_DIR.
# Dependencies: ecryptfs
# TODO: Make SECRET_DIR an cli-option.
# See: eumount.sh

SECRET_DIR="sec"
# insert passphrase into keyring
ecryptfs-insert-wrapped-passphrase-into-keyring

# get mount dir by reading the conf files 2nd field
sec_mnt="$(cat "$HOME/.ecryptfs/$SECRET_DIR.conf" | awk '{print $2}')"

# make mount dir
mkdir -p "$sec_mnt"

# mount secret directory
printf "Mounting '$SECRET_DIR' to '$sec_mnt': "
mount.ecryptfs_private "$SECRET_DIR" && echo "[SUCCESS]" || echo "[FAILURE]"

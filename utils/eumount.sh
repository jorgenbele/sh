#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2016 [dd.mm.yyyy]
# File: eumount.sh
# Description: 
#   Unmounts the encrypted secret directory 
#   $HOME/.$SECRET_DIR from $HOME/$SECRET_DIR.
# Dependencies: ecryptfs
# TODO: Make SECRET_DIR an cli-option.
# See: emount.sh

SECRET_DIR="sec"
# insert passphrase into keyring
#ecryptfs-insert-wrapped-passphrase-into-keyring

# get mount dir
sec_mnt="$(cat "$HOME/.ecryptfs/$SECRET_DIR.conf" | awk '{print $2}')"

# unmount secret directory
printf "Unmounting '$SECRET_DIR' at '$sec_mnt' "
umount.ecryptfs_private "$SECRET_DIR" && printf "[SUCCESS]\n" || printf "[FAILURE]\n"

# remove mount dir
rmdir "$sec_mnt"

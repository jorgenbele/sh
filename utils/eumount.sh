#!/bin/sh
SECRET_DIR="sec"
# insert passphrase into keyring
#ecryptfs-insert-wrapped-passphrase-into-keyring

# get mount dir
sec_mnt="$(cat "$HOME/.ecryptfs/$SECRET_DIR.conf" | awk '{print $2}')"

# unmount secret directory
printf "Unmounting '$SECRET_DIR' at '$sec_mnt' "
umount.ecryptfs_private "$SECRET_DIR" && printf "[SUCCESS]\n" || printf "[FAILURE]\n" && exit 0

# remove mount dir
rmdir "$sec_mnt"

notification -d "emount"
notification -t 10 -k "eumount" -a "ecryptfs: unmounting..." &

#!/bin/sh
SECRET_DIR="sec"

success() {
    notification -d "emount"
    notification -t 10 -k "eumount" -a "ecryptfs: unmounting..." &
    echo "[SUCCESS]"
    exit 0
}

failure() {
    echo "[FAILURE]"
    exit 1
}


# insert passphrase into keyring
#ecryptfs-insert-wrapped-passphrase-into-keyring

# get mount dir
sec_mnt="$(awk '{print $2}' < "$HOME/.ecryptfs/$SECRET_DIR.conf")"

# unmount secret directory
printf "Unmounting '$SECRET_DIR' at '$sec_mnt' "
umount.ecryptfs_private "$SECRET_DIR" && success || failure

# remove mount dir
rmdir "$sec_mnt"



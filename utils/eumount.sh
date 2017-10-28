#!/bin/sh
if [ -z "$SECRET_DIR" ]; then
    if [ -n "$1" ]; then
        SECRET_DIR="$1"
    else
        SECRET_DIR="sec"
    fi
fi

success() {
    notification -d "emount:$SECRET_DIR"
    notification -t 10 -k "eumount" -a "ecryptfs: $SECRET_DIR unmounted" &
    echo "[SUCCESS]"
    exit 0
}

failure() {
    echo "[FAILURE]"
    notification -t 30 -k "eumount" -a "ecryptfs: $SECRET_DIR unmounting failed!" &
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



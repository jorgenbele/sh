#!/bin/sh
SECRET_DIR="sec"

success() {
    # write to statusline
    notification -k "emount" -a "ecryptfs: mounted" &
    echo "[SUCCESS]"
    exit 0
}

failure() {
    # write to statusline
    notification -t 10 -k "emount_failure" -a "ecryptfs: failed" &
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


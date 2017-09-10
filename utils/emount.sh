#!/bin/sh
SECRET_DIR="sec"
# insert passphrase into keyring
ecryptfs-insert-wrapped-passphrase-into-keyring

# get mount dir
sec_mnt="$(cat "$HOME/.ecryptfs/$SECRET_DIR.conf" | awk '{print $2}')"

# make mount dir
mkdir -p "$sec_mnt"

# mount secret directory
printf "Mounting '$SECRET_DIR' to '$sec_mnt': "
mount.ecryptfs_private "$SECRET_DIR" && echo "[SUCCESS]" || echo "[FAILURE]"

# write to statusline
notification -k "emount" -a "ecryptfs: mounted" &

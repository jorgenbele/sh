#!/bin/sh
# Ecryptfs setup script
# arch-wiki: https://wiki.archlinux.org/index.php/ECryptfs#Manual_setup
# - inspired by source: https://bazaar.launchpad.net/~ecryptfs/ecryptfs/trunk/view/head:/src/utils/ecryptfs-setup-private#L96

###############################################################################
# This script creates a wrapped passphrase                                    #
###############################################################################
# The files are encrypted with a random key which is stored in a file that is #
# encrypted by our passphrase, meaning that we can change the passphrase by   #
# decrypting the random key and re-encrypting it with another passphrase.     #
###############################################################################

# bytes
KEYBYTES=10 # max

PRIVATE_DIR="sec"

# encrypted data path
secret_path="$HOME/.$PRIVATE_DIR"

# decrypted data path 
mounted_path="$HOME/$PRIVATE_DIR"

# configuration path forementioned containing paths and more
config_path="$HOME/.ecryptfs"

# wrapped passphrase file
wrapped_prassphrase_file="$config_path/wrapped-passphrase"
echo "wrapped_prassphrase_file: $wrapped_prassphrase_file"

# secret sig file
secret_sig_file="$config_path/$PRIVATE_DIR.sig"


# source: https://bazaar.launchpad.net/~ecryptfs/ecryptfs/trunk/view/head:/src/utils/ecryptfs-setup-private#L96
random_passphrase() {
	bytes=$1
	# Pull $1 bytes of random data from /dev/random,
	# and convert to a string of hex digits
	od -x -N $bytes --width=$bytes /dev/random | head -n 1 | sed "s/^0000000//" | sed "s/\s*//g"
}

userenter_passphrase() {
    # save current tty settings
    original="$(stty -g)"


    while true; do

        # ask for password
        stty "$original"
        printf "Enter password: " 1>&2
        # disable echo
        stty -echo
        pass_0="$(head -n1)"

        stty "$original"
        printf "\nRe-enter password: " 1>&2
        stty -echo
        pass_1="$(head -n1)"

        if [ "$pass_0" = "$pass_1" ]; then
            stty "$original"
            printf "%s" "$pass_0"
            return
        fi

        echo "\nPasswords not matching, try again..." 1>&2
    done

    # restore tty settings
    stty "$original"
}

setup_secret_directories() {
    # make directories and set permissions
    mkdir -p -m 700 "$secret_path"  # permission 700
    mkdir -p -m 500 "$mounted_path" # permission 500
    mkdir -p "$config_path"         # default permissions

    # generate "secret.conf" config file
    echo "$secret_path $mounted_path ecryptfs" > "$config_path/secret.conf"
}

## Main
password="$(userenter_passphrase)"

# create dirs
setup_secret_directories

# create passphrase using ecryptfs-wrap-passphrase
# using method from the source code of ecryptfs-setup-private
random_key="$(od -x -N $KEYBYTES --width=$KEYBYTES /dev/random | head -n 1 | sed "s/^0000000//" | sed "s/\s*//g")"
# wrap passphrase
printf "%s\n%s" "$random_key" "$password" | ecryptfs-wrap-passphrase "$wrapped_passphrase_file" || echo "Failed to wrap passphrase" && exit 1

# backup any existing wrapped-passphrase or sig files; we DO NOT destroy this
# modified from source: https://bazaar.launchpad.net/~ecryptfs/ecryptfs/trunk/view/head:/src/utils/ecryptfs-setup-private#L96
timestamp="$(date +%Y%m%d%H%M%S)"
for i in "$wrapped_prassphrase_file" "$secret_sig_file"; do
	if [ -s "$i" ]; then
		mv -f "$i" "$i.$timestamp" || echo "Could not backup existing data" "[$i]"
	fi
done

# insert passphrase into keyring to get the id
keyring_id="$(printf "%s" "$password" | ecryptfs-insert-wrapped-passphrase-into-keyring "$wrapped_prassphrase_file" - | sed 's/.*\[//g;s/\].*//g')"
echo "Keyring_id: $keyring_id"

# write id to secret_sig_file
echo "$keyring_id" > "$secret_sig_file"

# append (same id) to secret_sig_file to encrypt filenames
# TODO: add another key for filename encryption
echo "$keyring_id" >> "$secret_sig_file"

echo "Done."

# list directories
echo "== Directory listing =="
ls -alR "$config_path"
ls -al "$mounted_path"
ls -al "$secret_path"
echo "======================="

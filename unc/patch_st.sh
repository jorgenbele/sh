#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: xx.xx.2017 [dd.mm.yyyy]
# File: xinput_toggle.sh 
# Description: 
#   System breaking patch to 'st' - literally.
#   Updates the fontsize in the st binary by using a sed replacement.
# Dependencies: $BIN/st_original

# Warning: this is not to be used anywhere at any time.

# This script patches the st binary to change the font size....
# It accomplishes this by using a sed replacement on "pixelsize="
# This means that the fontsize must be two digits otherwise it breaks.

fontsize="(cat /tmp/fontsize)"

if [ "$fontsize" = "" ]; then
    fontsize="25"
fi

if [ -f "$BIN/st_original" ]; then
    sed "s/pixelsize=[0-9][0-9]*/pixelsize=$fontsize/g" "$BIN/st_original" > "$BIN/st"
    chmod +x "$BIN/st"
else
    echo "File: '$BIN/st_original' not found. QUITTING!" 1>&2
fi

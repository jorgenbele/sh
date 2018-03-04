#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 30.06.2017 [dd.mm.yyyy]
# File: terminal.sh
# Description: 
#   Tries to start a terminal emulator, selecting from
#   a premade list of terminal emulators.

# exists(): checks if command exist and prints path if so, 
#           returns 0 on success, otherwise failure
exists() {
    command -v "$1"
}

# default TERMINALS string 
if [ -z "$TERMINALS" ]; then
    TERMINALS="alacritty termite urxvt rxvt-unicode st rxvt xterm"
fi

# execute whichever terminal command is found first and exit
for term in $TERMINALS; do
    if exists $term; then
      $term
      exit  
    fi
done

# Print error
echo "Unable to launch terminal, found no terminal emulator" 2>&1
echo "TERMINALS=\"$TERMINALS\"" 2>&1

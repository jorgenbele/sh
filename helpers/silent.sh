#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 24.07.2017 [dd.mm.yyyy]
# File: silent.sh
# Description: Sets alsa-volume to 0

echo "Setting volume of Master to 0"
amixer set Master "0%"

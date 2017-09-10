#!/bin/sh
# Author: Jørgen Bele Reinfjell
# Date: 01.08.2017
# File: readifytxt.sh
# Description: Uses readify and xclip to readify clipboard text.
# Dependencies: readify, xclip
xclip -selection clipboard -o | readify "$@" | xclip -selection clipboard -i

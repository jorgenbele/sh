#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 12.07.2017 [dd.mm.yyyy]
# File: set-title.sh
# Description: Sets terminal-emulator's window title.

printf "\033]0;$@\007"

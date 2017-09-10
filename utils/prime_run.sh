#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 01.06.2017 [dd.mm.yyyy]
# File: prime_run.sh
# Description: 
#   Script to launch "$@" using the descrete graphics card.
# Dependencies: none (but will not work without PRIME support)

DRI_PRIME=1 $@

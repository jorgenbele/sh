#!/bin/sh
# Author: Jørgen Bele Reinfjell 
# Date: 29.06.2017 [dd.mm.yyyy]
# File: tcli-finished.sh
# Description: 
#   Transmission torrent finished script.
#   Writes information about the finished torrent to the statusbar

## Environment variables which are set by transmission on completion
#TR_APP_VERSION
#TR_TIME_LOCALTIME
#TR_TORRENT_DIR
#TR_TORRENT_HASH
#TR_TORRENT_ID
#TR_TORRENT_NAME

tempwrite ~/.not "Torrent '$TR_TORRENT_NAME' finished" 20

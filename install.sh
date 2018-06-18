#!/bin/sh
# Author: Jørgen Bele Reinfjell
# Date: 13.11.2017 [dd.mm.yyyy]
# File: install.sh
# Description: Install scripts into $HOME/bin.

# Set install directory.
[ -z "$INSTALL_DIR" ] && INSTALL_DIR="$HOME/bin"

# Newline separated list of files
FILES="
bak-gen.sh
graphics/1080p.sh
graphics/1440p.sh
graphics/1800p.sh
helpers/dmenu_start.sh
helpers/docx-mupdf.sh
helpers/docx2pdf.sh
helpers/emacs-client.sh
helpers/emacs-server.sh
helpers/officefarm.sh
helpers/readifytxt.sh
helpers/redshift-disable.sh
helpers/redshift-enable.sh
helpers/silent.sh
helpers/yt.sh
helpers/yt.sh
rofi/rofi-locate.sh
rofi/rofi-wallpaper.sh
statusbar/reset-bar.sh
statusbar/statusbar.sh
statusbar/update-bar.sh
terminal.sh
unc/beet_cue_ape_split_import.sh
unc/beet_cue_split_import.sh
unc/cuetag.sh
unc/xinput_toggle.sh
utils/change-dpi.sh
utils/emount.sh
utils/eumount.sh
utils/notification.sh
utils/notification_timer.sh
utils/prime_run.sh
utils/run_notification.sh
utils/sgit.sh
utils/torrent.sh
utils/try.sh
"
# stripext(string ...): remove the (last) file extension
stripext() {
    echo "$@" | sed 's~\..*$~~g'
}

# installpath(path): get install path
installpath() {
    echo "${INSTALL_DIR}/$(stripext $(basename $1))"
}

# Convert DIRS and FILES to nul-terminated strings, store in temp file (for use by du)
# Source: https://unix.stackexchange.com/questions/102891/posix-compliant-way-to-work-with-a-list-of-filenames-possibly-with-whitespace
set -f; IFS='
    '                             # turn off variable value expansion except for splitting at newlines
for path in $FILES; do
    set +f; unset IFS         # restore globbing and field splitting at all whitespace
    inspath="$(installpath "$path")"
    cp "$path" "$inspath"
    echo cp "$path" "$inspath"

    chmod +x "$inspath"
    echo chmod +x "$inspath"
done
set +f; unset IFS             # restore globbing again in case $INPUT was empty
echo "Done."

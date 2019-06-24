#!/bin/sh
# File: checker
# Author: Jørgen Bele Reinfjell
# Date: 04.02.2019 [dd.mm.yyyy]
# Description:
#   Script used for routinely checks

LIST_1337X_FILE="$HOME/.1337x.list"

# $@ list of search terms to check
# returns - list of terms if search returns a nonempty list
check_1337x() {
        ret="$(1337x --terse search $@ 2>/dev/null)"
        if [ -n "$ret" ]; then
                echo "$ret"
                return 0
        fi    
        return 1
}

# $1 command
# $2 line separated list of strings
args_by_lines() {
        local command="$1"
        shift 1

        set -f; IFS='
'                             # turn off variable value expansion except for splitting at newlines

        for elem in $1; do
                if $command $elem > /dev/null; then
                        echo "$elem"
                fi
        done
        set +f; unset IFS             # restore globbing again in case $INPUT was empty
        #echo 'Running:' $command $args
}

echo "checker :: Checking 1337x searches"
echo "Opening: $LIST_1337X_FILE"
entries="$(cat "$LIST_1337X_FILE")"
if [ -n "$entries" ]; then
	nentries="$(echo "$entries" | wc -l)"
else
	nentries=0
fi

out="$(args_by_lines check_1337x "${entries}")"
if [ -n "$out" ]; then
	nout="$(echo "$out" | wc -l)"
else
	nout=0
fi
[ -n "$out" ] && echo "$out"
echo "$nout out of $nentries changed"

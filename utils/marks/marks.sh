# File: marks.sh
# From file: shrc (personal shell config file)
# Date: XX.XX.2016 [dd.mm.yyyy]
# Author: Jørgen Bele Reinfjell
# Description: A 'bookmark' utility for the (POSIX) shell.

### NOTE: This file has to be evalated by the shell (sourced), it cannot function by itself as a regular script.
### IT IS PROBABLY NOT USEFUL OUTSIDE OF THE .shrc FILE. BUT IS HERE FOR COMPLETENESS

[ -z "$MARKS_FILE" ] && MARKS_FILE="$HOME/.marks"

ENABLE_PRETTY_PRINT_MARKS=1
ENABLE_REGEX_CHANGE_MARKS=1

# __regex_match_dir(dir, regex): tries to match a regex for a file/dir in 'dir'.
__regex_match_dir() {
    # check for multiple matches

    # First try to get a single match for a file starting with the string
    # designated by regex, this is because most of the time the regex
    # is just the "word" we are searching for.
    local regex
    local matches
    local nmatches

    regex="${2}.*"
    matches="$(ls -a "$1" | grep -m 1 -w "${regex}")"
    nmatches="$(echo "${matches}" | wc -l)"
    if [ "$nmatches" = 1 ]; then
        # only one match found: return value of match
        echo "$matches"
        return 0
    fi

    #
    matches="$(ls -a "$1" | grep "$2")"
    nmatches="$(echo "${matches}" | wc -l)"
    if [ "$nmatches" -gt 1 ]; then
        # multiple matches found: just print them
        # https://unix.stackexchange.com/questions/31753/how-to-run-grep-on-a-single-column#31755
        # https://stackoverflow.com/questions/11534173/how-to-use-awk-variables-in-regular-expressions#11534330
        __log "Multiple matches for '$1':"
        #__log "$(echo "${matches}")"
        __log "${matches}"
        return 1
    else
        # only one match found: return value of match
        echo "$matches"
    fi
}

__marks=""
__marks_setup=0

__marks_load_file() {
    # Load marks from file if specified.
    local pmarks
    pmarks=""
    if [ -n "$1" ]; then
        local marks_file
        local oifs

        while IFS="$(print '\n')" read -r line; do
            local mark_name
            local mark_dir

            # XXX: not the most efficient way...
            mark_name="$(echo "$line" | awk -F= '{print $1}')"
            mark_dir="$(echo "$line" | awk -F= '{print $2}')"
            eval "export ${mark_name}=${mark_dir}"
        done < "$1"
    fi
}

__mark_dir() {
    if [ $__marks_setup = 0 ]; then
        __marks_load_file "$MARKS_FILE"
        __marks_setup=1
    fi

    if [ -z "$1" ]; then
        marks
        return 1
    elif [ "$1" = "-h" ]; then
        __log "m - dir marker"
        __log "Usage: m name [dir]"
        return 1
    fi

    if [ -z "$2" ]; then
        # goto mark
        mark=$(eval echo '$mark_'${1})
        #echo "mark: $mark"

        if [ -n "$mark" ]; then
            # mark exists
            __custom_cd "$mark"
        else
            if [ -n "$ENABLE_REGEX_CHANGE_MARKS" ]; then
                # mark does not exist try to find using
                # regular expression (select first entry)
                # THIS SHOULD BE MADE MORE SIMPLE!
                #
                #env | grep "mark_" | grep "$1" | head -1 | awk -F '=' '{print $2}'
                # get list of marks which fit the pattern
                local pmarks
                pmarks="$(env | grep "mark_" | grep "$1")"

                # check for multiple matches
                lines="$(echo "$pmarks" | wc -l)"
                if [ "$lines" -gt 1 ]; then
                    # multiple matches found: just print them
                    # https://unix.stackexchange.com/questions/31753/how-to-run-grep-on-a-single-column#31755
                    # https://stackoverflow.com/questions/11534173/how-to-use-awk-variables-in-regular-expressions#11534330
                    __log "Multiple matches for '$1':"
                    __log "$(marks | awk -v regex="$1" '{ if ($1 ~ regex) { print }}')"
                    return 1
                else
                    # only one match found: change directory
                    mark="$(echo "$pmarks" | awk -F '=' '{print $2}')"
                fi

            fi

            if [ -n "$mark" ]; then
                # mark exists
                __custom_cd "$mark"
            else
                __log "Mark '$1' does not exist"
                return 1
            fi
        fi
    else
        # create mark
        eval "export mark_${1}=$2"
        #echo "export mark_${1}=$2"
        __log "Marked '$1' as '$2'"
        __marks="$marks $1=$2"
    fi
}

marks() {
    if [ -n "$ENABLE_PRETTY_PRINT_MARKS" ]; then
        tmpf="$(mktemp)"
        env | grep "mark" | sed "s/mark_//g" | sed "s/=/ -> /g" | sort -k 1 > "$tmpf"
        column -t "$tmpf"
        rm "$tmpf"
    else
        env | grep "mark" | sed "s/mark_//g"
    fi
}

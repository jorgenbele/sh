#!/bin/sh
# File: skeys.sh
# Author: Jørgen Bele Reinfjell
# Date: 29.06.2018 [dd.mm.yyyy]
# Description: 
#     Helper script for starting ssh-agent with shorthand notations
#     for identities.
# Dependencies:
#     ssh-agent
#     ssh-add

VERBOSE=false
SSH_AGENT_STARTED=false

log() {
	echo "$@" 1>&2
}

verbose() {
	"$VERBOSE" && log "$@"
}

has_commands() {
	while [ -n "$1" ]; do
		command -v "$1" > /dev/null || return "$?"
		shift 1
	done
	return 0
}

check_deps() {
	has_commands "ssh-agent" "ssh-add" && verbose "All dependencies found"
}

# start_agent: Starts the ssh-agent.
start_agent() {
	verbose "Starting ssh-agent: eval \"$(ssh-agent)"\"
	eval "$(ssh-agent)"
	SSH_AGENT_STARTED=true
}

# load_identity(): Loads a identify from file.
# $1 - file
load_identity() {
	if ! "$SSH_AGENT_STARTED"; then
		start_agent
	fi

	verbose "Loading identity from file: $1"
	ssh-add "$1"
	ret="$?"
	if [ "$ret" = 2 ]; then
		log "Failed to contact authentification agent"
	elif [ "$ret" = 0 ]; then
		verbose "Successfully added identity!"
	else
		log "Failed to add identity!"
	fi
	return "$ret"
}

# load_identity_files: Loads identities from the IDENTITY_FILES env variable.
load_identity_files() {
    set -f; IFS='
    '                     # turn off variable value expansion except for splitting at newlines
    for id_file in $IDENTITY_FILES; do
        set +f; unset IFS # restore globbing and white space splitting
        load_identity "$id_file"
    done
    set +f; unset IFS
} 

usage() {
	echo "Usage: $0 [-dhv] [-f FILE] [IDENTITY ...]"
	echo "  -d        exits with no error code if all dependencies are set up"
	echo "  -h        display this message and quit"
	echo "  -v        enable verbose output"
	echo "  -f FILE   load identity from the specified file"
	echo ""
	echo "Env variables: Loads all identities specified in the newline 
          separated list of paths in IDENTITY_FILES "
	echo "Example: $0 -v -f some_file github_id_rsa gitlab_id_rsa"
}

opts="dhvf:"
while getopts "$opts" arg; do
	case "$arg" in
		'd') check_deps; exit "$?"   ;;
		'v') VERBOSE=true;  ;;
		'h') usage; exit 0; ;;
		'f') load_identity "$OPTARG" ;; # load using filename directly
	esac
done

# Load all identities specified by names
shift "$((OPTIND-1))"
while [ -n "$1" ]; do
	if ! load_identity "$HOME/.ssh/$1_id_rsa"; then
		log "Quitting early due to previous errors. "
		exit "$?"
	fi
	shift 1
done

## Load from env variable IDENTITIY_FILES
# Treat all following args as paths
verbose "IDENTITY_FILES: $IDENTITY_FILES"
if [ -n "$IDENTITY_FILES" ]; then
    load_identity_files
fi

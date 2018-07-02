#!/bin/sh
# File: pushbak.sh
# Author: Jørgen Bele Reinfjell
# Date: 22.06.2018 [dd.mm.yyyy]
# Description: Push files to backup server(s) using rsync.

#!import commands.verbose
#!import commands.log
#!import commands.has_commands
#!import commands.check_deps

dependencies="rsync"

VERBOSE=false

usage() {
	echo "Usage: $0 [-hv] [-r REMOTE] [-t torrent|local] PATH ..."
	echo "  -d            exits with no error code if all dependencies are set up"
	echo "  -h            display this message and quit"
	echo "  -v            enable verbose output"
	echo "  -r            specify a remote server to push to, can be repeated"
	echo "  -t  TYPE      specified the backup type - one of the following:"
	echo "      local     used for files local to the host device "
	echo "      torrent   used specifically for torrent files, which"
	echo "                should be placed in a special directory"
	echo ""
	echo "Example: $0 -v -t torrent -r username@server:backup_path dls/some_torrent"
	return 0
}

# add_remote(): Adds a remote paths to the list of remotes.
add_remote() {
	REMOTES="${REMOTES}
	$@"
}

# execute_remote(): Executes a command on the remote server.
# $1 - remote
# $2 - cmd
execute_remote() {
	ssh "$1" "$2"
	local ret="$?"

	if [ "$ret" = 255 ]; then
		log "Failed to connect to remote"
		return 1;
	elif [ "$ret" -ne 0 ]; then
		log "Remote command failed... Are you sure permissions are setup correctly?"
		return 1
	fi
	return 0
}

# setup_remote(): Creates the necessary files/directories using env. variables.  
# $1 - remote
# $2 - remote path
setup_remote() {
	# setup dirs
	log "Setting up remote dirs..."
	log "Creating directories: $2"
	execute_remote "$1" "mkdir -p ${2} && exit 0"
	if [ "$?" = "0" ]; then
		log "Successfully setup remote directories"
	else
		log "Failed to setup remote directories [$?]"
		return 1
	fi
	return 0
}

# push_to_remote(): Push files/dirs to remote
# $1 - remote with FULL PATH
# $2 - paths
push_to_remote() {
	_path="$(echo $1 | sed 's/^.*://g')"
	_remote="$(echo $1 | sed 's/:.*$//g')"
	verbose "path: $_path"
	verbose "remote: $_remote"

	# Create directories at remote
	setup_remote "$_remote" "$_path" || return 1

	log "Executing rsync --recursive --verbose $2 $1"
	rsync --archive --progress --recursive --verbose $2 $1
}

month() {
	date "+%m"
}

day() {
	date "+%d"
}

year() {
	date "+%Y"
}

timestamp() {
	date "+%Y_%m_%d_%H_%M_%S"
}

# push_local(): Push files with -t local
# $1 - remote
# $2 - paths
push_local() {
	FULL_REMOTE="$1/local/$(year)/$(hostname)/$(timestamp)"
	log "pushing locally to ${FULL_REMOTE}"
	push_to_remote "$FULL_REMOTE" "$2"
}

# push_torrent(): Push files with -t torrent
# $1 - remote
# $2 - paths
push_torrent() {
	FULL_REMOTE="$1/torrents/"
	log "pushing torrents to ${FULL_REMOTE}"
	push_to_remote "$FULL_REMOTE" "$2"
}

# $1 - type
# $2 - remote
# $3 - paths
push() {
	case "$1" in 
		'local')    push_local   "$2" "$3";;
		'torrent')  push_torrent "$2" "$3";;
	esac
}

# Main
[ "$#" = 0 ] && usage && exit 1

OPTS='dhvt:r:'
TYPE='local'

while getopts "$OPTS" arg; do
    case "$arg" in
        'v') VERBOSE=true;  ;;
    esac
done
OPTIND=1

while getopts "$OPTS" arg; do
	case "$arg" in
        'd') check_deps; exit "$?"  ;;
		'h') usage; exit 0; ;;

		# Type
		't') 
			TYPE="$OPTARG"
			;;
		# Remote
		'r')
			verbose "Adding remote: $OPTARG"
			add_remote "$OPTARG"
			;;
	esac
done

[ -z "$REMOTE" ] && REMOTE="rsyncbak@debserv:/mnt/backup"
[ -z "$REMOTES" ] && REMOTES="$REMOTE"  # List of remotes separated by newlines.

# Treat all following args as paths
shift "$((OPTIND-1))"
_PATHS="$@"
verbose "REMOTES: $REMOTES"
verbose "PATHS: $_PATHS"
[ -z "$_PATHS" ] && log "No paths provided. Quitting!" && exit 1

# Do for all remotes
set -f; IFS='
    '                             # turn off variable value expansion except for splitting at newlines
for remote in $REMOTES; do
	set +f; unset IFS # restore globbing and white space splitting
	log "Pushing to remote $remote of type $TYPE"
	push "$TYPE" "$remote" "$_PATHS"
done
set +f; unset IFS
echo "Done."

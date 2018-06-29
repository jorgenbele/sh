#!/bin/sh
# File: 	sgit.sh
# Author: 	Jørgen Bele Reinfjell
# Date: 	18.06.2018 [dd.mm.yyyy]
#
# Desciption: 
#	A script used to create "bare" repositories 
#	on a remote git server.
#
# Security:
#   None. Does not check for paths including '..' etc.
#
# Environment variables:
#	GIT_SERVER  The remote server hostname. (default: debserv)
#	GIT_USER    The remote git username.    (default: git)
#	GIT_SUBDIR  The subdirectory to create the repository in
#                   (defaults to $USER). This means that the
#                   remote remote path will be:
#                   $GIT_USER@$GIT_SERVER:$GIT_SUBDIR/$REPOSITORY
#                   Where $REPOSITORY is the repo-name.
#			
# Authentication:
#	Authentication is done via SSH keys, which are
#	assumed to be available. (Can be setup to use
#	ssh-agent(1) or other alternatives).
#	
# Dependencies:
#	git
#	ssh
#	rsync
dependencies="git ssh rsync"

VERBOSE=false

[ -z "$GIT_SERVER" ] && GIT_SERVER="debserv"
[ -z "$GIT_USER"   ] && GIT_USER="git"
[ -z "$GIT_SUDIR"  ] && GIT_SUBDIR="$USER"

verbose() {
	"$VERBOSE" && log "$@"
}

log() {
	echo "$@" 1>&2
}

has_commands() {
    ret=0
	while [ -n "$1" ]; do
		if ! command -v "$1" > /dev/null; then
            if [ -z "$missing" ]; then
                missing="$1"
            else
                missing="$missing $1"
            fi
            ret=1
        fi
		shift 1
	done
    echo "$missing"
	return $ret
}

check_deps() {
    missing_deps=$(has_commands $dependencies)
    if [ "$?" = 0 ]; then
        verbose "All dependencies found: $dependencies"
    else
        verbose "Midding dependencies: $missing_deps"
    fi
}

# execute_remote(): Executes a command on the remote server.
execute_remote() {
	ssh "${GIT_USER}@${GIT_SERVER}" "$@"
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
# $1 - repo path
# $2 - repo name (used at remote)
setup_remote() {
	# setup dirs
	log "Setting up remote..."
	log "Creating directories: /home/${GIT_USER}/${GIT_SUBDIR}/${2}.git"
	execute_remote "cd /home/${GIT_USER} && mkdir -p ${GIT_SUBDIR}/${2}.git && exit 0"
	if [ "$?" = "0" ]; then
		log "Successfully setup remote"
	else
		log "Failed to setup remote [$?]"
		return 1
	fi
	return 0
}

# create_bare(): Creates a bare repository.
# $1 - repo path
# $2 - repo name (used at remote)
create_bare() {
	setup_remote || return 1
	execute_remote "cd /home/${GIT_USER}/${GIT_SUBDIR}/${2}.git && git --bare init && exit 0"
	if [ "$?" = "0" ]; then
		log "Created bare repository on remote"
	else
		log "Failed to create bare repository on remote [$?]"
		return 1
	fi
	return 0
}

# setup_remote_url(): Sets up origin URL for a repository.
# $1 - repo path
# $2 - repo name (used at remote)
setup_remote_url() {
	log "Setting up remote urls..."
	cd "$1" 
	# try to remove existing remote
	git remote remove origin > /dev/null 2>/dev/null
	git remote add origin "${GIT_USER}@${GIT_SERVER}:/home/${GIT_USER}/${GIT_SUBDIR}/${2}.git/"
	if [ "$?" = 0 ]; then
		log "Successfully setup remote for repository: ${2}"
	else
		log "Failed to setup remote for repository: ${2}"
		return 1
	fi
	return 0
}

# create_bare_copy(): Copies the repository to the remote as a bare repository.
# $1 - repo path
# $2 - repo name (used at remote)
create_bare_copy() {
	setup_remote || return 1
	local remote_url="/home/${GIT_USER}/${GIT_SUBDIR}/${2}.git/"
	rsync -uav "$1/.git/" "${GIT_USER}@${GIT_SERVER}:${remote_url}" 
	if [ "$?" = "0" ]; then
		log "Copied ${2} to remote at ${GIT_USER}@${GIT_SERVER}:${remote_url}"
		printf "Converting repository to bare repository: " 1>&2
		execute_remote "cd ${remote_url} && git config --bool core.bare true" > /dev/null
		if [ "$?" = 0 ]; then
			printf "success.\n" 1>&2
		else
			printf "failure.\n" 1>&2
			return 1
		fi
	else
		log "Failed to create bare repository on remote: ${remote_url} [$?]"
		return 1
	fi
	return 0
}

usage() {
	echo "Usage: $0 [-hv] [-u GIT_USER] [-s GIT_SERVER] [-d GIT_SUBDIR] [-bcr REPO] [MODE]"
	echo "  -h              Display this message and quit"
	echo "  -v              Enable verbose output"
    echo "  -d              Exits with no error code if all dependencies are set up"
    echo "  -b  REPO_PATH   Initiates a bare repo at remote host"
    echo "  -c  REPO_PATH   Copies a repo to the remote host"
    echo "  -r  REPO_PATH   Sets up origin URL for the given repository"
    echo
    echo "  -s  GIT_SERVER  Set the git server to use"
    echo "  -u  GIT_USER    Set the username to use at the remote"
    echo "  -p  GIT_SUBDIR  Set the subdirectory to hold the repository (must be )"
	echo
    echo "MODE can be one of the following:"
	echo "  bare    Initializes an empty repository at the remote host"
	echo "  copy    Copies (and only copies) a local repository"
	echo "              to the remote host and sets it as a bare repo"
	echo "  remote  Copies local repository to the remote (bare repo)"
	echo "              host and sets origin url to remote host"
    echo
    echo "Dependencies: $dependencies"
}

opts="hvbcrs:u:p:d"
while getopts "$opts" arg; do
    case "$arg" in
        'v') VERBOSE=true; ;;
    esac
done
OPTIND=1

while getopts "$opts" arg; do
    case "$arg" in
        's') GIT_SERVER="$OPTARG";  ;;
        'u') GIT_USER="$OPTARG";    ;;
        'p') GIT_SUBDIR="$OPTARG";  ;;
        'd') check_deps; exit "$?"; ;;

        'h') usage; exit 0; ;;
        'b') MODE='bare';   ;;
        'c') MODE='copy';   ;;
        'r') MODE='remote'; ;;
    esac
done

shift "$(($OPTIND-1))"

verbose "GIT_SERVER=${GIT_SERVER}"
verbose "GIT_USER=${GIT_USER}"
verbose "GIT_SUBDIR=${GIT_SUBDIR}"

if [ -z "$MODE" ]; then
    verbose "No mode selected using flags: using $1"
    MODE="$1"
    shift 1
fi

# Main
if [ "$#" = 0 ]; then
    log "No repository specified. Quitting."
    exit 2;
fi
repo_path="$1"
repo_name="$(basename $1)"

verbose "repo_path=${repo_path}"
verbose "repo_name=${repo_name}"

if [ -z "$repo_name" ]; then
    log "Repository name not provided. Quitting."
    exit 1
fi

case "$MODE" in
    b*) create_bare      "$repo_path" "$repo_name"; exit "$?"; ;;
	c*) create_bare_copy "$repo_path" "$repo_name"; exit "$?"; ;;
	r*)
		setup_remote     "$repo_path" "$repo_name" || exit "$?"
		create_bare_copy "$repo_path" "$repo_name" || exit "$?"
		setup_remote_url "$repo_path" "$repo_name" || exit "$?"
		exit "$?"
		;;
	'')
		usage
		exit 0
		;;
	*) 
        log "Unknown mode: \"$MODE\". Quitting."
		exit 0
		;;
esac

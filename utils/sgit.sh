#!/bin/sh
# File: 	sgit.sh
# Author: 	Jørgen Bele Reinfjell
# Date: 	18.06.2018 [dd.mm.yyyy]
#
# Desciption: 
#	A script used to create "bare" repositories 
#	on a remote git server.
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
setup_remote() {
	# setup dirs
	log "Setting up remote..."
	log "Creating directories: /home/${GIT_USER}/${GIT_SUBDIR}/${GIT_REPO}.git"
	execute_remote "cd /home/${GIT_USER} && mkdir -p ${GIT_SUBDIR}/${GIT_REPO}.git && exit 0"
	if [ "$?" = "0" ]; then
		log "Successfully setup remote"
	else
		log "Failed to setup remote [$?]"
		return 1
	fi
	return 0
}

# create_bare(): Creates a bare repository.
create_bare() {
	setup_remote || return 1
	execute_remote "cd /home/${GIT_USER}/${GIT_SUBDIR}/${GIT_REPO}.git && git --bare init && exit 0"
	if [ "$?" = "0" ]; then
		log "Created bare repository on remote"
	else
		log "Failed to create bare repository on remote [$?]"
		return 1
	fi
	return 0
}

# setup_remote_url(): Sets up origin URL for a repository.
setup_remote_url() {
	log "Setting up remote urls..."
	GIT_REPO="$(basename "$1")"
	cd "$1" 
	# try to remove existing remote
	git remote remove origin > /dev/null 2>/dev/null
	git remote add origin "${GIT_USER}@${GIT_SERVER}:/home/${GIT_USER}/${GIT_SUBDIR}/${GIT_REPO}.git/"
	if [ "$?" = 0 ]; then
		log "Successfully setup remote for repository: ${GIT_REPO}"
	else
		log "Failed to setup remote for repository: ${GIT_REPO}"
		return 1
	fi
	return 0
}

# create_bare_copy(): Copies the repository to the remote as a bare repository.
# $1 - path to repo
create_bare_copy() {
	GIT_REPO="$(basename "$1")"
	verbose "GIT_REPO=$GIT_REPO"
	setup_remote || return 1
	local remote_url="/home/${GIT_USER}/${GIT_SUBDIR}/${GIT_REPO}.git/"
	rsync -uav "$1/.git/" "${GIT_USER}@${GIT_SERVER}:${remote_url}" 
	if [ "$?" = "0" ]; then
		log "Copied ${repo_name} to remote at ${GIT_USER}@${GIT_SERVER}:${remote_url}"
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
	echo "Usage: $0 [-v] [bare|copy] REPOSITORY"
	echo "	  -v      Enable verbose output"
	echo
	echo "    bare	  Initializes an empty repository at the remote host"
	echo
	echo "    copy	  Copies (and only copies) a local repository"
	echo "            to the remote host and sets it as a bare repo"
	echo
	echo "    remote  Copies local repository to the remote (bare repo)"
	echo "            host and sets origin url to remote host"
}

if [ "$1" = "-v" ]; then
	VERBOSE=true
	shift 1
fi

verbose "GIT_SERVER=${GIT_SERVER}"
verbose "GIT_USER=${GIT_USER}"
verbose "GIT_SUBDIR=${GIT_SUBDIR}"

# Main
case "$1" in
	'bare')  
		GIT_REPO="$2"
		create_bare
		exit 0
		;;
	'copy') 
		create_copy "$2"
		exit 0
		;;
	'remote')
		setup_remote "$2"
		create_bare_copy "$2"
		setup_remote_url "$2"
		exit 0
		;;
	*) 
		GIT_REPO="$1"
		create_bare
		exit 0
		;;
esac

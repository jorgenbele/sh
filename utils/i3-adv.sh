#!/bin/sh
# File: 	i3-adv.sh
# Author: 	Jørgen Bele Reinfjell
# Date: 	11.07.2018 [dd.mm.yyyy]
#
# Desciption: 
#	A script used to ease have 'up' and 'down' workspaces
#	for each individual workspace. 
#
# Dependencies:
#	i3-msg

dependencies="i3-msg"

VERBOSE=false

get_workspace() {
	echo $(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name') | sed 's~"~~g'
}

workspace_to_state() {
	echo "$@" | cut -b -2
}

change_to_workspace() {
	i3-msg "workspace $@"
}

move_to_workspace() {
	i3-msg "move container to workspace $@"
}

workspace_without_state() {
	state="$(workspace_to_state "$@")"
	has_state=false
	case "$state" in
		'u_') has_state=true;;
		'd_') has_state=true;;
	esac
	if "$has_state"; then
		echo "$@" | cut -b 3-
	else
		echo "$@"
	fi
}

opts="mhudpn"

MOVE_TOGGLE=false
while getopts "$opts" arg; do
	case "$arg" in
		'h') 	echo "Usage: $0 [-hud]"
			echo "  -h  Display this message and quit."
			echo "  -u  Change to upper workspace"
			echo "  -d  Change to lower workspace"
			echo "  -m  Move selected window toggle"
			echo "  -p  Change to previous workspace"
			echo "  -n  Change to next workspace"
			exit 1
			;;

		'm') 	
			echo "MOVING"
			MOVE_TOGGLE=true
			;;
	esac
done
OPTIND=1

if "$MOVE_TOGGLE"; then
	ACTION=move_to_workspace
else
	ACTION=change_to_workspace
fi

workspace_with_state="$(get_workspace)"
state="$(workspace_to_state "$workspace_with_state")"
echo "workspace_with_state:$workspace_with_state"
echo "state:$state"
workspace="$(workspace_without_state "${workspace_with_state}")"
echo "workspace:$workspace"

while getopts "$opts" arg; do
	case "$arg" in
		'u')
			echo "UP"
			case "$state" in
				'u_') ;; # DO NOTHING, ALREADY AT UPPER WORKSPACE
				'd_') cmd=""$ACTION" "${workspace}"" ;; # GO TO NORMAL
				*)    cmd=""$ACTION"  "u_${workspace}"" ;;
			esac
			;;

		'd') 
			echo "DOWN"
			case "$state" in
				'u_') cmd=""$ACTION" "${workspace}"" ;; 
				'd_') ;; # DO NOTHING, ALREADY AT LOWER WORKSPACE
				*)    cmd=""$ACTION" "d_${workspace}"" ;;
			esac
	esac
done
echo "cmd:$cmd"
$cmd

#!/bin/sh
# ;-P
[ -z "$1" ] && read -p "Select a room: " CAM || CAM=$1
room_status=$( \
	curl -sSL chaturbate.com/$CAM | \
	grep -w window.initialRoomDossier | \
	sed 's|\u0022||g' | sed 's|\\||g' | \
	awk -F "room_status: " '{print$2}' | awk -F "," '{print$1}' \
	)
[ -n "$room_status" ] && echo $room_status || echo "error"
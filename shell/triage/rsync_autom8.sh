#!/bin/sh

# this should become a rsync wrapper. not sure if it would still be useful in current age...

# quick rsync shortcuts

# rsync_over_ssh
### The fastest remote directory rsync over ssh archival some dude on the internet in the year can muster (40MB/s over 1gb NICs)
# backup
### custom backup option that should leave no file behind while still leaving the chance to sort out duplicate directories
function print_usage () {

printf \
"Usage: bash rsync_automation.sh [automation] [source_dir] [dest_dir]

Current automations:
------------------------------------------------------------------------
	c, copy			simple rsync copy

	b, backup		copy dest. data to source and from
				source back to dest., with --delete

	s, ssh			transfer over ssh [host declaration as usual]

	bs, backup_over_ssh	both options
------------------------------------------------------------------------
	-h, --help		print this message

This script can cause serious data loss if misused. Please read carefully.\n"
}

# help
if [[ -z $1 ]] || [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "help" ]; then
	print_usage
	exit 1
fi
#
# do-not-fuck-up checks
if ! [[ $1 == *"/"* ]]; then
if [[ -n $2 ]] && [[ -n $3 ]]; then

	case $1 in

	c|copy)
		rsync -aHAXxv --numeric-ids --progress $2 $3;;

	b|backup)
		rsync -aHAXxv --numeric-ids --progress $3 $2;
		printf "\n\n\nHALFWAY THROUGH. TAKE YOUR TIME TO CHECK FOR DUPLICATES OR PRESS ENTER TO CONTINUE.n\n\n"; read -p "";
		rsync -aHAXxv --numeric-ids --delete-after --progress $2 $3;;

	s|ssh)
		rsync -aHAXxv --numeric-ids --progress -e "ssh -T -o Compression=no -x" $2 $3;;

	bs|backup_over_ssh)
		rsync -aHAXxv --numeric-ids --progress -e "ssh -T -o Compression=no -x" $3 $2;
		rsync -aHAXxv --numeric-ids --delete-after --progress -e "ssh -T -o Compression=no -x" $3 $2;;

	*)
		printf "Not a valid option.\n";
		print_usage;;
	esac

else
	printf ">Please specify source and destination.\n"
	print_usage; exit 1
fi
else
	printf ">It looks that you have not selected an automation.\n"
	print_usage; exit 1
fi

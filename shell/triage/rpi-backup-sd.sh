#!/bin/sh

# quit on fail
set -e
## run checks

# run as root
[ $UID -ne 0 ] && echo "Please run this script as root." && exit 1
# need device name
[ -z $1 ] && echo "Please provide device name [/dev/sdX] as argument." && exit 1
# does device exists?
! [ -b $1 ] && echo "Device $1 doesn't exist!" && exit 1
# if a directory is specified, make sure it exists
[ -n "$2" ] && \
	! [ -d $2 ] && echo "Output folder $2 is not a folder or doesn't exist!" && exit 1
# dependencies check
DEPS="pishrink parted partclone.dd"
for dep in $DEPS; do
	! [ $(command -v  $dep) ] && \
	echo "This script relies on $dep. Please install it and try again." && exit 1
done

## set vars
WDIR=${2:-$(pwd)} # set current dir if not specified
filename="sdcard-bak"
device_name=$1
today="$(date +%d%m%y)"
image_full="${filename}-${today}.img"
image_shrink="${filename}-${today}-shrink.img"

## do it
echo "Directory selected is $WDIR."
# ask and clone device
read -p "Backing up device ${device_name} to ${image_full}. Press ENTER to continue:"
partclone.dd -s $device_name -o $WDIR/${image_full}
# shrink device
echo "Done. Now shrinking image ${image_full} to ${image_shrink}..."
pishrink -v $WDIR/${image_full} $WDIR/${image_shrink}
# ask and remove original
read -p "Done. Do you want to remove full-size image? [y/N] " yn
case $yn in
	Y|y)	echo "Okay. Removing..."; rm -v ${WDIR}/${image_full};;
	*)	echo "Not removing original.";;
esac
# done
echo "Done."
printf "File located in $(ls ${WDIR}/${image_shrink}) \n"

#!/bin/sh

set -e

CHROOT_DIR="/mnt/target"
[ -d $CHROOT_DIR ] || (echo "$CHROOT_DIR does not exist." ; exit 1)

read -p "Make sure you have mounted the correct partition to $CHROOT_DIR [and relative boot partition] then press ENTER: "
read -p "Press ENTER again, just to make sure: "
# mount
mount -v --types proc /proc $CHROOT_DIR/proc
mount -v --rbind /sys $CHROOT_DIR/sys
mount -v --make-rslave $CHROOT_DIR/sys
mount -v --rbind /dev $CHROOT_DIR/dev
mount -v --make-rslave $CHROOT_DIR/dev
mount -v --bind /run $CHROOT_DIR/run
mount -v --make-slave $CHROOT_DIR/run

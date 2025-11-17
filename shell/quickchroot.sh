#!/bin/sh
set -e
CHROOT_DIR="${1:-/mnt/target}"
[ -d $CHROOT_DIR ] || (echo "$CHROOT_DIR does not exist." ; exit 1)
read -p "Make sure you have mounted the right filesystem on $CHROOT_DIR [with relative boot partitions] then press ENTER: "
read -p "Press ENTER again, just to make sure: "
mount -v --types proc /proc $CHROOT_DIR/proc
for i in sys dev run; do
    mount -v --rbind /$i $CHROOT_DIR/$i
    mount -v --make-rslave $CHROOT_DIR/$i
done
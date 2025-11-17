#!/bin/sh

# ~ fetched from some gentoo user

[ -r conf ] && . ./conf

# I don't trust anything but the kernel to keep a sane state here, so I don't
# (ab)use init to get this job done, nor do I count on myself actually knowing
# what is or isn't mounted (some packages can mount extra filesystems, like binfmt_misc).
# So, for process slaughter, I use:

PREFIX=<chroot_dir>
FOUND=0

for ROOT in /proc/*/root; do
    LINK=$(readlink $ROOT)
    if [ "x$LINK" != "x" ]; then
        if [ "x${LINK:0:${#PREFIX}}" = "x$PREFIX" ]; then
            # this process is in the chroot...
            PID=$(basename $(dirname "$ROOT"))
            kill -9 "$PID"
            FOUND=1
        fi
    fi
done

if [ "x$FOUND" = "x1" ]; then
        echo
        # repeat the above, the script I'm cargo-culting this from just re-execs itself
fi

#And for umounting chroots, I use:

PREFIX=<chroot_dir>
COUNT=0

while grep -q "$PREFIX" /proc/mounts; do
    COUNT=$(($COUNT+1))
    if [ $COUNT -ge 20 ]; then
        echo "failed to umount $PREFIX"
        if [ -x /usr/bin/lsof ]; then
            /usr/bin/lsof "$PREFIX"
        fi
        exit 1
    fi
    grep "$PREFIX" /proc/mounts | \
        cut -d\  -f2 | LANG=C sort -r | xargs -r -n 1 umount || sleep 1
done

umount -R $PREFIX
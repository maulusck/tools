#!/bin/sh
# sign liquorix kernels for secure boot. run after each kernel update.
set -eu

me=${0##*/}
say() { echo "$me: $*"; }
die() { echo "$me: $*" >&2; exit 1; }

if [ "$(id -u)" -eq 0 ]; then
	as_root() { "$@"; }
else
	command -v sudo >/dev/null || die "not root and no sudo"
	as_root() { sudo "$@"; }
fi

# keys live with the human, never /root. userless box -> /etc.
if [ -n "${SUDO_USER:-}" ]; then
	keydir=$(getent passwd "$SUDO_USER" | cut -d: -f6)/.keys/secureboot
elif [ "$(id -u)" -ne 0 ]; then
	keydir=${HOME:?}/.keys/secureboot
else
	keydir=/etc/secureboot
fi
keydir=${SECUREBOOT_KEYDIR:-$keydir}
key=$keydir/MOK.key crt=$keydir/MOK.crt cer=$keydir/MOK.cer

umask 077
mkdir -p "$keydir"
[ -f "$key" ] && [ -f "$crt" ] || {
	openssl req -new -x509 -newkey rsa:4096 -nodes -days 3650 \
		-keyout "$key" -out "$crt" -subj "/CN=Liquorix $(hostname)/" 2>/dev/null ||
		die "keygen failed"
	say "generated $crt"
}
[ -f "$cer" ] || openssl x509 -in "$crt" -outform DER -out "$cer"

found=0
for k in /boot/vmlinuz*liquorix*; do
	[ -f "$k" ] || continue
	found=1
	if sbverify --cert "$crt" "$k" >/dev/null 2>&1; then
		say "ok     $k"
	elif as_root sbsign --key "$key" --cert "$crt" --output "$k" "$k" >/dev/null 2>&1 &&
		sbverify --cert "$crt" "$k" >/dev/null 2>&1; then
		say "signed $k"
	else
		say "FAILED $k -- damaged, reinstall this kernel package"
	fi
done
[ "$found" = 1 ] || die "no liquorix kernel in /boot"

if as_root mokutil --test-key "$cer" 2>/dev/null | grep -q "already enrolled"; then
	say "enrolled $cer"
else
	as_root mokutil --import "$cer"
	say "staged -- reboot, pick 'Enroll MOK'"
fi

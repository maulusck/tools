#!/bin/sh
# sign liquorix kernels for secure boot. run after each kernel update.
set -eu

keydir="$HOME/.keys/secureboot"
key="$keydir/MOK.key"
crt="$keydir/MOK.crt"
cer="$keydir/MOK.cer"

# key: generate once
if [ ! -f "$key" ] || [ ! -f "$crt" ]; then
	mkdir -p -m 700 "$keydir"
	openssl req -new -x509 -newkey rsa:4096 -nodes -days 3650 \
		-keyout "$key" -out "$crt" -subj "/CN=Liquorix $(hostname)/"
	echo "generated $key"
fi
[ -f "$cer" ] || openssl x509 -in "$crt" -outform DER -out "$cer"

# sign: skip kernels already signed by our cert
found=0
for k in /boot/vmlinuz*liquorix*; do
	[ -f "$k" ] || continue
	found=1
	if sbverify --cert "$crt" "$k" >/dev/null 2>&1; then
		echo "ok    $k"
	else
		sudo sbsign --key "$key" --cert "$crt" "$k" --output "$k"
		echo "signed $k"
	fi
done
[ "$found" = 1 ] || { echo "no liquorix kernel in /boot" >&2; exit 1; }

# enroll: skip if cert already enrolled
if sudo mokutil --test-key "$cer" >/dev/null 2>&1; then
	echo "mok already enrolled"
else
	echo "setting a one-time MOK password (you'll re-enter it at reboot):"
	sudo mokutil --import "$cer"
	echo "mok staged -- reboot, pick 'Enroll MOK', enter that password"
fi

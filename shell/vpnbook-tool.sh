#!/bin/sh
set -euo pipefail

# Destination directory (default: ./vpnbook-certs)
dest="${1:-./vpnbook-certs}"
mkdir -p "$dest"

urls="
https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-pl226.zip
https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-de4.zip
https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-us1.zip
https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-us2.zip
https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-ca222.zip
https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-ca198.zip
https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-fr1.zip
https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-fr8.zip
"

echo '-- |v|p|n|b|o|o|k|_|t|o|o|l| --'

cd "$dest"

# Download all VPNBook zip files
for url in $urls; do
    filename=$(basename "$url")
    printf "Downloading %s... " "$filename"
    if wget -q -c -t0 -T15 "$url"; then
        echo "Done."
    else
        echo "Fail."
    fi
done

# Extract zip files
for zipfile in vpnbook-*.zip; do
    [ -f "$zipfile" ] || continue
    printf "Extracting %s... " "$zipfile"
    if 7z e -aoa "$zipfile" >/dev/null; then
        rm -f "$zipfile"
        echo "Done."
    else
        echo "Fail."
    fi
done

cd - >/dev/null
echo "Certs synced in $dest."

# Download password image
password_img="$dest/password.png"
curl -s -o "$password_img" https://www.vpnbook.com/password.php

username="vpnbook"

# OCR password if tesseract is available
if command -v tesseract >/dev/null 2>&1; then
    password=$(tesseract -l eng "$password_img" - | head -n1)
    echo "Username: $username. Password: $password. Image saved in $password_img."
else
    echo "Username: $username. Password image saved at $password_img. Install 'tesseract' for automatic reading."
fi
#!/bin/sh

### CONF

install_dir="./vpnbook-certs"

### END

[ -d $install_dir ] || mkdir -p $install_dir

packages="
	https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-pl226.zip
	https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-de4.zip
	https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-us1.zip
	https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-us2.zip
	https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-ca222.zip
	https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-ca198.zip
	https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-fr1.zip
	https://www.vpnbook.com/free-openvpn-account/vpnbook-openvpn-fr8.zip
"

cd $install_dir
for package in $packages; do (
	printf "Downloading '$package'... "
#	wget -q -c -t 0 -T 15 $package && echo "Done." || echo "Fail."
); done
cd - >/dev/null

echo "\nCerts downloaded in '$install_dir'."

tmp_file="$install_dir/password.png"
curl -s -o $tmp_file "https://www.vpnbook.com/password.php"

username="vpnbook"
password=$(tesseract -l eng $tmp_file - | head -n1)

echo "Username is '$username'. Password is OCR identified as '$password'. Image version in '$tmp_file'."

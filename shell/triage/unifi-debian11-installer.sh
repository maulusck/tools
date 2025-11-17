#!/bin/sh

#   This script installs the Unifi Controller application on a fresh Debian 11 machine.
#   It installs dependencies, configures the internal firewall as per Unifi documentation
#   and adds repos for Java, MongoDB and Unifi application.

#   A great thanks goes to Unifi for utilizing EOL, obsolete, vulnerable software for
#   their application and for developing Java backends which get your machine infected
#   with chinese mining scripts.

set -e

if ! [ $(id -u) = 0 ]; then
	echo "This script must be run as root."
	exit 1;
fi

# system preparation
PACKAGES="htop bmon tmux iotop curl wget ufw ca-certificates gnupg gnupg2 qemu-guest-agent zram-tools ca-certificates apt-transport-https"

apt update && apt full-upgrade -y
apt install $PACKAGES -y
systemctl enable --now qemu-guest-agent
systemctl enable --now zramswap

# configure firewall
TCP_PORTS="22 8080 443 8443 8880 8843 6789 27117"
UDP_PORTS="3478 5514 5656:5699 10001 1900"
for port in $TCP_PORTS ; do (echo TCP: $port && ufw allow proto tcp to 0.0.0.0/0 port $port) done
for port in $UDP_PORTS ; do (echo UDP: $port && ufw allow proto udp to 0.0.0.0/0 port $port) done
ufw enable

# Java 8
curl -fsSL "https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public" | sudo gpg --dearmor --yes -o /usr/share/keyrings/adoptopenjdk-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/adoptopenjdk-archive-keyring.gpg] https://adoptopenjdk.jfrog.io/adoptopenjdk/deb bullseye main" | sudo tee /etc/apt/sources.list.d/adoptopenjdk.list
sudo apt-get update && sudo apt-get install -y adoptopenjdk-8-hotspot

# MongoDB 3.6
wget -qO - https://www.mongodb.org/static/pgp/server-3.6.asc | sudo apt-key add -
echo "deb https://repo.mongodb.org/apt/debian stretch/mongodb-org/3.6 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list

# Unifi
echo 'deb https://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg
sudo apt-get update && sudo apt-get install unifi -y

# initialize from scratch
apt update && apt full-upgrade -y
apt autoremove && apt clean && apt autoclean
apt update && apt full-upgrade -y
sleep 5 && read -p "Press ENTER to reboot: "
reboot

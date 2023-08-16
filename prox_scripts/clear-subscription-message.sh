#!/bin/bash

[ $UID -ne 0 ] && (echo "Please run as root." ; exit 1)

# warning
echo "
	This might not be working anymore...\
	Trying anyway...
"
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && \
systemctl restart pveproxy.service

echo "Done."

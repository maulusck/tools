#!/bin/sh

# boot checks
if [ $UID -ne 0 ]; then
        echo "Please run this script as root!"; exit 1
# check cert name
else if [ -z $1 ]; then
        echo "Please provide a certificate filename [no extension] as one and only argument"; exit 1
else

# envvars
certs_dir='/etc/openvpn/keys'
build_dir='/root/build_dir'
packages_dir='/root/packages'
cert_name=$1
easyrsa_dir='/usr/share/easy-rsa'

# confirmation
read -p "You are building a certificate for ${cert_name}. Press ENTER twice to confirm or Ctrl+C to exit: "
read -p "Press ENTER one more time: "

# start build process and exit on error
set -e

cd ${certs_dir}
echo "Beginning procedure..."
# set no password if specified
if [ "$2" == "nopass" ]; then
        ${easyrsa_dir}/easyrsa build-client-full ${cert_name} nopass
else
        ${easyrsa_dir}/easyrsa build-client-full ${cert_name}
fi
read -p "Certificate has been created. Press ENTER to build a package, or Ctrl+C to exit now: "

# retrieve file
cd ${build_dir}
cp -v ${certs_dir}/pki/issued/${cert_name}.crt ./
cp -v ${certs_dir}/pki/private/${cert_name}.key ./

# this script supposes you have already a preset .ovpn file in the build directory
cp default.ovpn $cert_name.ovpn
sed -i "s/certname/${cert_name}/g" ${cert_name}.ovpn
sed -i "s/keyname/${cert_name}/g" ${cert_name}.ovpn
# create tarball
tar cvzf ${packages_dir}/${cert_name}.tgz \
        ./${cert_name}.crt ./${cert_name}.key \
        ./${cert_name}.ovpn ./ta.key ./ca.crt
printf "Certificate package has been created in " && ls ${packages_dir}/${cert_name}.tgz && printf ".\n"
# cleanup
echo "Cleaning up now..."
for file in ${cert_name}.ovpn ${cert_name}.crt ${cert_name}.key; do \
                (shred -n100 -v ${file} && rm -v ${file}) done
cd && echo "Done."

fi
fi

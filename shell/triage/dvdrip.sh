#!/bin/sh
set -e
usrnm=$(whoami)
echo ${usrnm}
RIP_DIR=/home/${usrnm}/Videos/
#
#
#echo ": UTILITY STARTING..."
read -p "	>>Insert output name and format[name.format]: " name
folder_name=$(echo ${name} | awk -F .  '{print $1}')
read -p "	>>Press Enter to start copying from DVD..."
#dvdbackup -M -p --input=/dev/sr0 --output=${RIP_DIR}/${folder_name}
printf "	>>Press Enter to start encoding in "
				echo $(echo ${name} | awk -F .  '{print $2}')"..."
				read -p ""
echo ": preparing data..."
cd ${RIP_DIR}/${folder_name}
pwd
mv -v ./*/* ./
rmdir -v ./*/*
HandBrakeCLI -i ./VIDEO_TS --main-feature -o ${name}
echo
echo ": Done."
echo
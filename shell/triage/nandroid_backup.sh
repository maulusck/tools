#!/bin/sh

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

# netcat-based nandroid backup
# - dd full partition blocks out of an Android device to a hard drive
#
# TODO:
# fdisk doesn't bloody work god knows why really
# - revert process [dd from pc backup to device partition]
# - backup multiple partitions
# - create tar backup mode [guide at EOF]
# - crash test
# - add colors
# - ...?
#
# https://github.com/maulusck

# receive user input #################################################
	if  [[ -n $1 ]]; then
		# print help
		if [[ $1 == "--help" ]] || [[ $1 == "-h" ]] || [[ $1 == "-help" ]]; then
			printf "-->Basic usage: bash nandroid_backup.sh [partition_to_backup] [backup_file]\n" && exit 1
		fi
		# set parameters
		DEV_PATH=$1
		BAK_PATH=$(echo $2 | rev | cut -d "/" -f 2- - | rev)
		BAK_FILE=$(echo $2 | rev | cut -d "/" -f 1 - | rev)
	fi

# DISCLAIMER
printf "\n\
>>> FULLY AUTOMATED NANDROID BACKUP >>> \n\n\
Since every device is different, this script requires that\n\
each user locates his storage name manually in order to avoid\n\
backing up the wrong partitions. If you're unsure about how to\n\
locate partitions, try playing and grepping with 'df -h', 'mount'\n\
and 'fdisk -l' in your Android shell.\n\n\
Make sure to have a rooted Android with BusyBox binaries installed.\n\
>>> Press ENTER to start the script or Ctrl+C to quit: "
read -p "" && printf "\n"

# check and install required packages ################################
function check_dependencies () {
	printf "Checking dependencies...\n"
	# checks for installed packages
	packages=("adb" "netcat" "pv" "xterm")
	for pkg in ${packages[@]}; do
		unset pkg_path
		pkg_path=$(which ${pkg})
		if [[ -n $pkg_path ]]; then
			printf "> ${pkg} is installed.\n"
		else
			tobeinstalled+=("$pkg")
			printf "> ${pkg} is NOT installed.\n"
		fi
	done
	# prompt to quick install:
	if [[ -n ${tobeinstalled[@]} ]]; then
		unset flag && flag=true
		while [ $flag == "true" ]; do
			flag=false
			read -p ">>> Do you want to install the missing packages? [Y/n]: " yn
			yn=${yn:-"Y"}
			case $yn in
				[Yy] )	printf "Installing...\n>>> APT is set as default package manager. If you use a different\npackage manager, enter the appropriate 'install package' string now: ";
					read -p "" install_cmd;
					install_command=${install_cmd:-"apt install -y"};
					sudo $install_cmd ${tobeinstalled[@]};;
				[Nn] )	printf "Dependencies not satisfied. Quitting.\n"; exit 1;;
				* )	printf "Not a valid option. Try again.\n------------------------------------------\n"; flag=true;;
			esac
		done
	else
		printf "Dependencies satisfied. Continuing...\n\n"
	fi
}


# check if adb is working ############################################
function check_adb () {
	printf "Checking ADB...\n"
	DEVICE=$(adb devices | grep -v List)/ DEVICE=$(echo $DEVICE | cut -d " " -f 1)
	if [[ -n $DEVICE ]]; then
		printf ">Device: $DEVICE connected.\n"
	else
		printf ">No device connected. Please connect your device and/or enable USB debugging.\n" && exit 1
	fi
	printf "\n"
}

# check if busybox is present on the device ################################
function check_busybox () {
	printf "Checking BusyBox...\n"
	function set_busybox () { BUSYBOX=${BUSYBOX:-"$(adb shell which busybox)"} ; } && set_busybox
	if [[ -n $BUSYBOX ]]; then
		printf ">BusyBox autolocated in $BUSYBOX.\n"
		read -p ">>>Press ENTER to accept or type in custom location [full path]: " BUSYBOX
	set_busybox
	else
		read -p ">>>BusyBox not found. Enter [full] path manually or press ENTER to exit the script: " BUSYBOX
	set_busybox
	fi
	if [[ $BUSYBOX == $(adb shell ls $BUSYBOX) ]]; then
		printf "BusyBox path set to $BUSYBOX. Continuing...\n\n"
	else
		printf "BusyBox not found at $BUSYBOX. Please install and try again.\n" && exit 1
	fi
}


# adb root permissions check
function check_root () {
	printf "Querying superuser privileges on your device, as this script will not work without them...\n"
	AMIROOT=$(adb shell su -c "whoami")
	if  [[ $AMIROOT == "root" ]]; then
		read -p ">>>Press ENTER when granted:"
	else
		printf "Superuser privileges denied. Exiting.\n" && exit 1
	fi
	printf "\n"
}


# set parameters, if not already
function set_parameters() {
	printf "Checking parameters...\n"
	# partition to back up
	if [[ -n $DEV_PATH ]]; then
		printf "Partition to back up is set as ${DEV_PATH}\n"
	else
		read -p ">>>Partition to back up is not set. Enter [full] path: " DEV_PATH
	fi
	unset flag && flag=true
	while [ $flag == "true" ]; do
		if [[ $DEV_PATH == $(adb shell ls $DEV_PATH) ]]; then
			printf ">$DEV_PATH selected. Printing info:\n\n"
			adb shell su -c 'fdisk -l ${DEV_PATH}' && flag=false
		else
			printf ">Path $DEV_PATH does not exist. Insert again: " DEV_PATH
			read -p "" DEV_PATH
		fi
	done
	# backup location
	if [[ -n $BAK_PATH ]] && [[ -n $BAK_FILE ]]; then
		printf "Backup location is set as ${BAK_PATH}/${BAK_FILE}.raw\n"
	else
		if ! [[ -n $HOME ]]; then HOME=$(cd ~ && pwd && cd - > /dev/null); fi
		read -p ">>>Backup location is not set. Enter [full] path or press ENTER to accept default [$HOME]: " BAK_PATH
		BAK_PATH=${BAK_PATH:-"$HOME"}
		# check whether path exists
		unset flag && flag=true
		while [ $flag == "true" ]; do
			# remove trailing slash if present
			if [[ -n $BAK_PATH ]] && [[ $(ls $BAK_PATH | rev | cut -c 1 -) == "/" ]]; then
			BAK_PATH=$($BAK_PATH | rev | cut -c 2- | rev); fi
			if [[ -d $BAK_PATH ]]; then
				printf ">Path $BAK_PATH set.\n"&& flag=false;
			else
				read -p ">>>Path $BAK_PATH does not exist. Insert again:" BAK_PATH
			fi
		done
		# backup filename
		read -p ">>>Backup filename is not set; Enter filename or press ENTER to accept default [nandroid_BAK.raw]: " BAK_FILE
		BAK_FILE=${BAK_FILE:-"nandroid_BAK"}
	fi
	# remove .raw extension
	if ! [[ -n $(echo $BAK_FILE | grep -v raw) ]]; then
	BAK_FILE=$(echo $BAK_FILE | rev | cut -c 5- | rev); fi
	# check for existing file
	if [[ -f $BAK_PATH/$BAK_FILE.raw ]]; then
		printf ">WARNING: $BAK_PATH/$BAK_FILE.raw already exists.\n" && flag=false
		read -p ">>>Press ENTER to remove or Ctrl+C to exit and sort it out: "
		rm -iv $BAK_PATH/$BAK_FILE.raw
	fi
	printf ">$BAK_PATH/$BAK_FILE.raw set as backup file.\n\n" && flag=false
}


# RAW - start sending backup from device ###################################
function raw_bak_client () {
	# open Xterm to start listening on the device. Change if running in a non-graphical environment
	# maybe make it using tmux?
	printf "RAW backup initialized: ${DEV_PATH} > ${BAK_PATH}/${BAK_FILE}.raw\n"
	read -p ">>>Press ENTER to begin sending from device [xterm window will be opened], or Ctrl+C to exit: "
	xterm -hold -e " \
	adb forward tcp:5555 tcp:5555>/dev/null					&& \
	echo '>Beginning transmission...'					&& \
	adb shell su -c '$BUSYBOX nc -l -p 5555 -e $BUSYBOX dd if=$DEV_PATH'	&& \
	echo 'Backup sent.'							&& \
	pkill nc && sleep 3 && exit						" &
}


# RAW - start receiving backup from server #################################
function raw_bak_server () {
	# start listening
	read -p "Press ENTER to start listening from device: "
	adb forward tcp:5555 tcp:5555
	nc 127.0.0.1 5555 | pv -i 0.5 > $BAK_PATH/$BAK_FILE.raw
}

# bad quits delete all
function trap_ctrlc () {
        # perform cleanup here
	echo
	read -p "Ctrl+C detected. Press ENTER to clean up: "
	rm -iv $BAK_PATH/$BAK_FILE.raw
#	pkill xterm
#	adb kill-server
        exit 2
}


# MAIN
check_dependencies
check_adb
check_busybox
check_root
set_parameters
# initialise trap to call trap_ctrlc function
# when signal 2 (SIGINT) is received
trap "trap_ctrlc" 2
# start backup
raw_bak_client
raw_bak_server
echo "The script has terminated. You should find your backup in ${BAK_PATH}/"


#Back up of a single partition (tar = only files and folders)
#In this case, you need the partition mounted. To see the list of mounted partitions type on Cygwin Terminal
#Code:
#adb shell mount
#Now you need to know where is mounted the partition you want to backup, for example the firmware is mounted on /system, which is the ROM.
#In this case you will have to open three terminals, because of android limitations:
#
#Open one Cygwin terminal and create a fifo, in /cache, for example, and redirect the tar there
#Code:
#adb forward tcp:5555 tcp:5555
#adb shell
#su
#/system/xbin/busybox mkfifo /cache/myfifo
#/system/xbin/busybox tar -cvf /cache/myfifo /system
#We have to do it this way because redirecting the tar to stdout (with - ) is broken on android and will corrupt the tar file.
#
#Open a second Cygwin terminal and type:
#Code:
#adb forward tcp:5555 tcp:5555
#adb shell
#su
#/system/xbin/busybox nc -l -p 5555 -e /system/xbin/busybox cat /cache/myfifo
#
#Open a third Cygwin terminal and type:
#Code:
#adb forward tcp:5555 tcp:5555
#cd /path/to/store/the/backup
#nc 127.0.0.1 5555 | pv -i 0.5 > system.tar
#
#You can browse the tar file with Winrar, Total Commander, PeaZip and almost any compression tool. Note that you shouldn't extract files or edit it since the tar format saves the permission and owner data for each file, that is lost when extracted to FAT / NTFS partitions and you will mess things when restoring.

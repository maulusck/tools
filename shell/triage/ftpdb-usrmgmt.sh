#!/bin/sh
set -e

# create in mariadb an entry for a pureftpd user, already
# configured set up for pbx servers [password too]

### functions
show_usage () {
printf "\
Usage: ./pbx-usrmgmt.sh [OPTION] [FILE]...

PBX FTP BACKUP SERVER - USER MANAGEMENT SCRIPT

Create, delete or simply show users of an FTP server's MariaDB backend.

  -a, --add <user>		create new <user> directory and db entry
  -d, --delete <user>		delete <user> from db entries (and directory)
  -l, --list			show list of current users in db

--------------- made with love ------------------
"
exit 0
}
# CREATE ftp user directory w/ permissions
mkdir_new_ftp_user () {
	mkdir -v /home/pbx-backup/backups/${1}
	chown $ADMIN:$ADMIN /home/pbx-backup/backups/${1}
}
# make SQL query - CREATE
sql_add_ftp_user () {
	COMMAND="USE ${DB}; INSERT INTO ${TABLE} \
		(\`User\`, \`status\`, \`Password\`, \`Uid\`, \`Gid\`, \`Dir\`, \`ULBandwidth\`, \
		\`DLBandwidth\`, \`comment\`, \`ipaccess\`, \`QuotaSize\`, \`QuotaFiles\`) VALUES \
		('pbx-backup-${1}', '1', MD5 ('${1}-BAK'), '${ADMIN_UID}', '${ADMIN_GID}', '${BAK_DIR}/${1}/', \
		'100', '100', '${1} PBX', '*', '50', '0')"
	echo " EXECUTING: ${COMMAND}"
	read -p "Press ENTER to confirm: "
	mariadb -e "${COMMAND}"
}
# get users from SQL
sql_list_ftp_users () {
	mariadb -e "USE ${DB}; select * from ${TABLE};"
}
# REMOVE ftp user directory w/ permissions
rmdir_new_ftp_user () {
	read -p "Do you want to remove user backups [${BAK_DIR}/${1}]? [y/N] " yn
case $yn in
	Y|y)	echo "Okay. Removing..."; rm -rfv ${BAK_DIR}/${1};;
	*)	echo "Not removing backups.";;
esac
}
# make SQL query - DELETE
sql_del_ftp_user () {
	COMMAND="USE ${DB}; DELETE FROM ${TABLE} \
		WHERE User = 'pbx-backup-${1}'"
	echo " EXECUTING: ${COMMAND}"
	read -p "Press ENTER to confirm: "
	mariadb -e "${COMMAND}"
}
# CREATE user - routine
create_user () {
	read -p "User to be created is ${1}. Press ENTER to start: "
	printf "\nCreating new user directory...\n\n"
	mkdir_new_ftp_user ${1}
	printf "\nCreating new SQL user...\n\n"
	sql_add_ftp_user ${1}
	printf "\nCurrent users:\n\n"
	sql_list_ftp_users

}
# DELETE user - routine
delete_user () {
	read -p "User to be DELETED is ${1}. Press ENTER to delete: "
	read -p "Press ENTER again, just to be safe: "
	printf "\nDeleting user directory ${1}...\n"
	rmdir_new_ftp_user ${1}
	printf "\nDeleting SQL entry...\n\n"
	sql_del_ftp_user ${1}
	printf "\nCurrent users:\n\n"
	sql_list_ftp_users
}
need_username () {
	echo "Please provide a username as argument."; exit 1
}

###

### set vars
DB="pureftpd"
TABLE="users"
ADMIN=pbx-backup
ADMIN_UID=2002
ADMIN_GID=2001
BAK_DIR="/home/pbx-backup/backups"

### main
[ -z ${1} ] && show_usage
# root check
[ $UID -ne 0 ] && echo "This script must be run as root." && exit 1
# sort between create/delete user or list only
case ${1} in
	# list only
	-l|-L|--list)
		sql_list_ftp_users;
		exit 0;;
	# create user
	-a|-A|--add)
		[ -z ${2} ] && need_username || create_user ${2};;
	# delete user
	-d|-D|--delete)
		[ -z ${2} ] && need_username || delete_user ${2};;
	# show help
	*)	show_usage;;
esac
# restart service when all is done
echo && read -p "Press ENTER to restart ftp service or Ctrl+C to exit: "
service pure-ftpd-mysql restart
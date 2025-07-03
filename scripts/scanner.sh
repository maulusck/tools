#!/bin/sh

# SANE automated scan. Custom options are for CanoScan LiDE 20 scanner

if [[ -n $1 ]]; then
	echo "Checking for device..."
	DEVICE=$(scanimage --list-devices | cut -d "'" -f 1 | cut -d "\`" -f 2)
	FORMAT=$(echo $1 | cut -d "." -f 2)
	read -p "Press ENTER to start scanning:"
	scanimage \
	--device "$DEVICE" \
	--mode Color --format=$FORMAT \
	--progress \
	--output-file \
	$1 \ # from here custom options
	--depth 16 \
	--resolution 1200
else
	echo "Please provide a filename as argument"
fi

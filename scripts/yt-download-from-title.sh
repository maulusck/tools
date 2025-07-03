
#!/bin/sh


# set up environment
#cp -n list.txt ongoing.txt
#konsole --hold --new-tab -e $SHELL -c "while true; do (ls -l --color=auto | grep -v -e .txt -e .sh && sleep 3 && clear) done" &
#konsole --hold --new-tab -e $SHELL -c "while true; do (cat ongoing.txt && sleep 3 && clear) done" &

# start
tempfile=$(mktemp)
youtube_dl_log=$(mktemp)
youtube-dl -j "ytsearch5:$*" > $tempfile

# workaround for lack of mapfile in bash < 4
# https://stackoverflow.com/a/41475317/6598435
# while IFS= read -r line
# do
#    youtube_urls+=("$line")
# done < <(cat $tempfile | jq '.webpage_url' | tr -d '"' )

# # for bash >= 4
mapfile -t youtube_urls < <(cat $tempfile | jq '.webpage_url' | tr -d '"' )
cat $tempfile | jq '.fulltitle, .webpage_url'

while :
do

# default is first result available; for choosing
# each file swap these two parts

	echo "Enter video number to download. [default=1]"
	read i
	i=${i:-1}

#	echo 'choosing first video:'
#	i=1

# to make numbering of videos more intuitive (start from 1 not 0)

	youtube-dl -x --audio-format mp3 ${youtube_urls[$i - 1]}
#	tail -n +2 ongoing.txt > ongoing.txt.tmp
#	mv ongoing.txt.tmp ongoing.txt
	exit
done



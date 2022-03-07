#!/bin/bash
#

#
# Aktivieren eines INOTIFY auf den FTP Upload Ordner
#
#
#
#
#
#mypidfile=~/camerawatch.sh.pid
mypidfile="$0"".pid"
srcpath=/home/kamera
scripts=/home/ubu/camerawatch
dstpath=/home/ubu/media

#trap "rm -f '$mypidfile’" 2
trap "rm -f $mypidfile" EXIT

echo $$ > "$mypidfile"
echo "$0"

#while pid=$(pgrep -o -f "/camerawatch.sh( |$)") && [ ${pid} -ne ${$} ] ; do
#    kill $pid
#done

inotifywait -mr -e create "$srcpath" |
while true; do
    while read $T path action file; do
        rm -f `ls -td -1 "$srcpath"/** | awk 'NR>50'`
        echo "The file '$file' appeared in directory '$path' via '$action'"


	# strip everything after the first instance of 'ISDIR'
	prefix=${action%%ISDIR*}
	# count number of characters in the string
	index=${#prefix}
	# ...and show the result...
	len=${#action}

	if [ "$index" -ge "$len" ]; then
		echo "is not dir"

		# Filesizewatch für Bilder / JPG
		prefix=${file%%jpg*}
		index=${#prefix}
		len=${#file}
		if [ "$index" -lt "$len" ]; then
			echo "is jpg"
			echo "sending parameters to jpg filesize observer"
			"$scripts"/filesizewatch_jpg.sh "$path" "$file" "$dstpath" &
		fi

		# Filesizewatch für Videos / MP4
		prefix=${file%%mp4*}
		index=${#prefix}
		len=${#file}
		if [ "$index" -lt "$len" ]; then
			echo "is mp4"
			echo "sending parameters to mp4 filesize observer"
			"$scripts"/filesizewatch_mpg-mpg.sh "$path" "$file" "$dstpath" &
		fi

		echo "done"

	else
		echo "is dir"
	fi

    done
done

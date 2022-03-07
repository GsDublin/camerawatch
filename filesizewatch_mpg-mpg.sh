#!/bin/bash
#

echo $0

path=$1			# Ordenr der zu überwachenden Datei
file=$2			# Dateiname der zu überwachenden Datei
destination=$3	# Zielordner der fertigen Datei / Media Ordner

scripts=/home/ubu/camerawatch

# split path into array
array=(`echo $path | sed 's/\//\n/g'`)

if printf '%s\n' "${array[@]}" | grep -q -P '^kamera$'; then
	echo "path ok"
else
	echo "path didnt contains kamera"
	exit;
fi

# should be camera number
cameranr=${array[2]}
echo "Kamera: $cameranr"

fhemhost="http://localhost:8083"
nasfolder=/mnt/kamera
naststfolder=@Recently-Snapshot

filenamearray=(`echo $file | sed 's/\./\n/g'`)
smallfile="${filenamearray[0]}_s.mp4"
fullfile="${filenamearray[0]}_f.mp4"

ff_timestamp="drawtext=text='%{eif\:0+(t/((1/24)*16))\:d}': x=0: y=h-text_h: fontsize=12:fontcolor=yellow@0.9: box=1: boxcolor=black@0.6"


# Cleaning destination directory string /
destarray=(`echo $destination | sed 's/\//\n/g'`)
var=$( IFS=$'/'; echo "${destarray[*]}" )
destination="/$var/"

echo "got folder: $path and file: $file dst:$destination"

echo "gifsmallfile $gifsmallfile"
echo "giffullfile $giffullfile"

token=$(wget -qO - --server-response "$fhemhost/fhem?XHR=1" 2>&1 | awk '/X-FHEM-csrfToken/{print $2}')
echo "fhem csrf: $token"

prefix=${file%%mp4*}
index=${#prefix}
len=${#file}
if [ "$index" -lt "$len" ]; then
#if [[ "$file" == *'mp4'* ]]; then
	echo "is mp4 file"
	cmd="setreading%20Kamera_Bewegung%20current_fullvideo%20$path$file"
	wget -q -O - "$hosturl/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"

	echo "starting size observer"

	# testing sizable changes
	oldsize=$(wc -c "$path$file" | awk '{print $1}')
	speed=$oldsize
	j=0
	sleep 4
	ctime=$((4))
	oaspeed=0
  
	while [[ "$j" -lt "3" ]] && [[ "$ctime" -lt "60" ]]
	do
		actsize=$(wc -c "$path$file" | awk '{print $1}')
		#speed=$((actsize/ctime/1024))
		sizediff=$((actsize-oldsize))
		speed=$((sizediff/2))
		if [ "$ctime" -gt "0" ]; then
			oaspeed=$((actsize/ctime/1024))
		fi
		echo "V $ctime $file $j: $oldsize $actsize ${speed}b/s"
		oldsize=$(wc -c "$path$file" | awk '{print $1}')
		sleep 2
		if [ "$sizediff" -le "0" ]; then
				j=$((j+1))
		else
				j=$((0))
		fi
		ctime=$((ctime+2))

		if [ "$ctime" -eq "12" ]; then
			ffmpeg -t 10 -y -i "$path$file" -s 320x240  -vf fps="fps=60/60" -fs 9000000  "$destination/$smallfile"
			readingsname="K${cameranr}_Kurzvideo"
			cmd="setreading%20Kamera_Upload%20${readingsname}_Datei%20$destination$smallfile"
			wget -q -O - "$fhemhost/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"
			echo "FHEM: $cmd"
		fi

	done

	srcsize=$(wc -c "$path$file" | awk '{print $1}')
	echo "src size: $srcsize"
	actsize=$(wc -c "$destination$file" | awk '{print $1}')
	echo "dst size: $actsize"
		echo "file stream finished"

	echo "send to ffmpeg"
	# zu gross ffmpeg -y -i "$path$file" -c:v copy -c:a copy -fs 10485760 "$destination$file"
	ffmpeg -y -i "$path$file" -s 320x240  -vf fps="fps=60/60" -fs 9000000  "$destination/$file"
	readingsname="K${cameranr}_Video"
	cmd="setreading%20Kamera_Upload%20${readingsname}_Datei%20$destination$file"
	echo "FHEM: $cmd"
	wget -q -O - "$fhemhost/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"

	cmd="setreading%20Kamera_Upload%20${readingsname}_Size%20$srcsize"
	echo "fhem $cmd"
	wget -q -O - "$fhemhost/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"

	cmd="setreading%20Kamera_Upload%20${readingsname}_Upload_s%20$ctime"
	echo "fhem $cmd"
	wget -q -O - "$fhemhost/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"

	cmd="setreading%20Kamera_Upload%20${readingsname}_Speed_s%20$oaspeed"
	echo "fhem $cmd"
	wget -q -O - "$fhemhost/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"

else
	echo "file has not .mp4 extension"
fi

echo "$0 done"

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

# Verbindung zu FHEM
fhemhost="http://localhost:8083"

# Cleaning destination directory string /
destarray=(`echo $destination | sed 's/\//\n/g'`)
var=$( IFS=$'/'; echo "${destarray[*]}" )
destination="/$var/"

echo "got folder: $path and file: $file dst:$destination"

prefix=${file%%jpg*}
index=${#prefix}
len=${#file}
if [ "$index" -lt "$len" ]; then

	echo "$file is jpg file"
	
	# should be camera number
	cameranr=${array[2]}
	echo "Kamera: $cameranr"

	echo "get fhem token"
	token=$(wget -qO - --server-response "$fhemhost/fhem?XHR=1" 2>&1 | awk '/X-FHEM-csrfToken/{print $2}')
	echo "got token:$token"
	
	readingsname="K${cameranr}_Bild"
	cmd="setreading%20Kamera_Upload%20${readingsname}_Name%20$file"
	echo "fhem $cmd"
	wget -q -O - "$fhemhost/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"

	echo "starting size observer"

	# testing sizable changes
	oldsize=$(wc -c "$path$file" | awk '{print $1}')
	speed=$oldsize
	j=0
	sleep 3
	ctime=$((3))
	oaspeed=0
	while [[ "$j" -lt "3" ]] && [[ "$ctime" -lt "60" ]]
	do
		actsize=$(wc -c "$path$file" | awk '{print $1}')
		#speed=$((actsize/ctime/1024))
		sizediff=$((actsize-oldsize))
		speed=$((sizediff/3))
		if [ "$ctime" -gt "0" ]; then
			oaspeed=$((actsize/ctime/1024))
		fi
		echo "P $ctime $file $j: $oldsize $actsize ${speed}b/s"
		oldsize=$(wc -c "$path$file" | awk '{print $1}')
		sleep 3
		if [ "$sizediff" -le "0" ]; then
				j=$((j+1))
		else
				j=$((0))
		fi
		ctime=$((ctime+3))
	done

	echo "file stream finished"

	echo "copy image to media directory"
	cp "$path$file" "$destination$file"

	actsize=$(wc -c "$path$file" | awk '{print $1}')
	echo "src size: $actsize"
		actsize=$(wc -c "$destination$file" | awk '{print $1}')
	echo "dst size: $actsize"

	#echo "copy file to destination directory"
	#cp "$path$file" "$destination$file"

	#echo "copy to nas directory"
	#sh "$scripts"/filetonas.sh "$path" "$file"


	echo "fhem csrf: $token"
	
	readingsname="K${cameranr}_Bild"
	cmd="setreading%20Kamera_Upload%20${readingsname}_Datei%20$destination$file"
	echo "fhem $cmd"
	wget -q -O - "$fhemhost/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"
	
	cmd="setreading%20Kamera_Upload%20${readingsname}_Size%20$actsize"
	echo "fhem $cmd"
	wget -q -O - "$fhemhost/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"
	
	cmd="setreading%20Kamera_Upload%20${readingsname}_Upload_s%20$ctime"
	echo "fhem $cmd"
	wget -q -O - "$fhemhost/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"
	
	cmd="setreading%20Kamera_Upload%20${readingsname}_Speed_s%20$oaspeed"
	echo "fhem $cmd"
	wget -q -O - "$fhemhost/fhem?cmd=$cmd&fwcsrf=$token&XHR=1"

else
	echo "file has not .jpg extension"
fi

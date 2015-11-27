#!/bin/bash
# Author:	benoit

f_settings(){ #settings for the program
	XLname="SYNOPHOTO_THUMB_XL.jpg" ; XLsize="1280x1280";
	Lname="SYNOPHOTO_THUMB_L.jpg" ; Lsize="800x800";
	Bname="SYNOPHOTO_THUMB_B.jpg" ; Bsize="640x640";
	Mname="SYNOPHOTO_THUMB_M.jpg" ; Msize="320x320";
	Sname="SYNOPHOTO_THUMB_S.jpg" ; Ssize="160x160";
	ORIGIFS=$IFS ; IFS=$(echo -en "\n\b")
}
makeline(){ #nice output
	printf '%*s\n' "${1:-${COLUMNS:-$(tput cols)}}" "" | tr " " "${2:-#}"
}

pause(){
   read -p "$*"
}

f_args(){
	if [[ $# == 1 ]] 
	then
		echo "working against directory $1"		
		filelist_cmd=$(find ${DIR} ( -type f -a ( -name "*.MOV" -o -name "*.mov" -o -name "*.MTS" -o -name "*.mts" -o -name "*.M2TS" -o -name "*.m2ts" -o -name "*.mp4" -o -name "*.AVI" -o -name "*.avi" ) ! -path "*@eaDir*" ))
	else
		echo "By default, we are working against /mnt/photo/flv_create.queue"
		echo "if you want, specify a directory as arg..."

		#replace base dir
		sed -i -e 's/volume1/mnt/g' flv_create.queue
		sed -i -e 's/'"$(printf '\015')"'//g' flv_create.queue
		
		filelist_cmd=$(cat /mnt/photo/flv_create.queue)
	fi
	makeline
	echo "file list:"
	echo ${filelist_cmd}
	makeline
	pause "ready ? press [enter] to start"

}

f_video_thumbs(){

	i=0

#	for f in `find ${DIR} \( -type f -a \( -name "*.MOV" -o -name "*.mov" -o -name "*.MTS" -o -name "*.mts" -o -name "*.M2TS" -o -name "*.m2ts" -o -name "*.mp4" -o -name "*.AVI" -o -name "*.avi" \) ! -path "*@eaDir*" \)`
	#echo ${filelist}
	for f in ${filelist_cmd}
		do
			# don't process first item (when dsm indexer is already working)
			#i=$(($i+1))
			#[ $i -le 1 ] && continue
			#[ $i -eq 3 ] && break

	 		echo -e "\nprocessing file : ${f}"
			vidName=`echo "${f}" |  awk -F\/ '{print $NF}'`
			vidDir=`echo "${f}" | sed s/"${vidName}"//g | sed s/.$//`
			[[ !(-d "${vidDir}/@eaDir/${vidName}") ]] && (echo "creating directory : ${vidDir}/@eaDir/${vidName}"; mkdir -p "${vidDir}/@eaDir/${vidName}"; chmod 775 "${vidDir}/@eaDir/${vidName}";)
			
			echo -e "\nSearching video conversions for ${f}"
			#[[ !(-f "${vidDir}/@eaDir/${vidName}"/'SYNOPHOTO_FILM_M.mp4') ]] && ( echo "   -- processing ${vidName}" ; ffmpeg -i "${vidDir}/${vidName}" -vcodec libx264 -vpre medium -ar 44100 "${vidDir}/@eaDir/${vidName}"/'SYNOPHOTO_FILM_M.mp4' 2> /dev/null ; echo  "   -- ${vidName} mp4 created";)

			[[ !(-f "${vidDir}/@eaDir/${vidName}"/'SYNOPHOTO_FILM.flv') ]] && ( echo "   -- processing ${vidName}" ;ffmpeg -i ${f} -y -r 12 -b 1024k -bt 1024k -f flv -acodec libmp3lame -ar 44100 -ac 2 -qscale 5 -s 852x480 -aspect 852:480 "${vidDir}/@eaDir/${vidName}/SYNOPHOTO_FILM.flv.temp" ;mv "${vidDir}/@eaDir/${vidName}/SYNOPHOTO_FILM.flv.temp" "${vidDir}/@eaDir/${vidName}/SYNOPHOTO_FILM.flv"; echo  "   -- ${vidName} mp4 created";)
			
			#[[ !(-f "${vidDir}/@eaDir/${vidName}"/'SYNOPHOTO_FILM_MOBILE.mp4') ]] && ( echo "   -- processing ${vidName}" ; ffmpeg -i "${vidDir}/${vidName}" -vcodec libx264 -vpre medium -ar 44100 -s 320x240 "${vidDir}/@eaDir/${vidName}"/'SYNOPHOTO_FILM_MOBILE.mp4' 2> /dev/null ; echo  "   -- ${vidName} mobile mp4 created";)			

			echo -e "\nSearching Thumbs For ${f}"
			[[ !(-f "${vidDir}/@eaDir/${vidName}/${XLname}") ]] && (ffmpeg -i "${vidDir}/${vidName}" -an -ss 00:00:03 -an -r 1 -vframes 1 "${vidDir}/@eaDir/${vidName}/${XLname}" 2> /dev/null ; echo "   -- ${XLname} thumbnail created";)
			[[ !(-f "${vidDir}/@eaDir/${vidName}/${Lname}") ]] && (convert -size ${XLsize} "${vidDir}/@eaDir/${vidName}/${XLname}" -auto-orient -resize ${Lsize} "${vidDir}/@eaDir/${vidName}/${Lname}"; echo "   -- ${Lname} thumbnail created";)
			[[ !(-f "${vidDir}/@eaDir/${vidName}/${Bname}") ]] && (convert -size ${Lsize} "${vidDir}/@eaDir/${vidName}/${Lname}" -auto-orient -resize ${Bsize} "${vidDir}/@eaDir/${vidName}/${Bname}"; echo "   -- ${Bname} thumbnail created";)
			[[ !(-f "${vidDir}/@eaDir/${vidName}/${Mname}") ]] && (convert -size ${Bsize} "${vidDir}/@eaDir/${vidName}/${Bname}" -auto-orient -resize ${Msize} "${vidDir}/@eaDir/${vidName}/${Mname}"; echo "   -- ${Mname} thumbnail created";)
			[[ !(-f "${vidDir}/@eaDir/${vidName}/${Sname}") ]] && (convert -size ${Msize} "${vidDir}/@eaDir/${vidName}/${Mname}" -auto-orient -quality 60 -resize ${Ssize} "${vidDir}/@eaDir/${vidName}/${Sname}"; echo "   -- ${Sname} thumbnail created";)		

			echo -e "\nSearching video thumb for ${f}"
			[[ !(-f "${vidDir}/@eaDir/${vidName}"/'SYNOVIDEO_TEMP.jpg') ]] && ( echo "   -- processing ${vidName}" ;ffmpeg -timelimit 180 -an -i ${f} -y -vframes 1 -ss 00:00:03 -f mjpeg "${vidDir}/@eaDir/${vidName}/SYNOVIDEO_TEMP.jpg" ;echo  "   -- ${vidName} thumb SYNOVIDEO_TEMP.jpg created";)
	done
}

f_exit(){ #exit message
	makeline
	echo " Now log into DSM and reindex your photos"
	echo " (Control Panel --> Media Indexing Service --> Re-index)"
	makeline
	IFS=$ORIGIFS
	exit 0
}

f_settings
f_args $*
f_video_thumbs
f_exit

#!/bin/bash

function abspath() { #https://superuser.com/questions/205127/how-to-retrieve-the-absolute-path-of-an-arbitrary-file-from-the-os-x
	pushd . > /dev/null; 
	if [ -d "$1" ]; 
	then 
		cd "$1"; dirs -l +0; 
	else 
		cd "`dirname \"$1\"`"; 
		cur_dir=`dirs -l +0`; 
		if [ "$cur_dir" == "/" ]; 
		then 
			echo "$cur_dir`basename \"$1\"`"; 
		else 
			echo "$cur_dir/`basename \"$1\"`"; 
		fi; 
	fi; 
	popd > /dev/null;
}

DIR=$(abspath $(dirname "$0"))
IMG="$DIR/screen.png"
TEMPLATE="template.svg"

while getopts "f:m:h" option
do
    case $option in
        f)
					IMG=$OPTARG
					echo "You selected the file $OPTARG"
					;;
				m)
					if [ "{$OPTARG,,}"="iphone6" ] || [ "{$OPTARG,,}"="iphone6s" ]
					then
						echo "Your screen is for $OPTARG"
						TEMPLATE="template_iphone6.svg"	
					fi
					;;
				h)
					echo "-f [screenshot_path] 		Select any png on your computer to get IVs"
					exit 0
    		;;
    esac
done

if [ ! -n "$(which bc)" ]
then
	echo "error: this script requires bc." 1>&2
fi

if [ ! -n "$(which convert)" ]
then
	echo "error: this script requires convert (imagemagick)." 1>&2
fi

if [ ! -n "$(which tesseract)" ]
then
	echo "error: this script requires tesseract." 1>&2
fi

function init
{
	rects="rectCP rectHP rectDust rectPkmName"
	echo "$TEMPLATE"
	for r in $rects
	do
		echo ">" $r 1>&2
		echo $r \
$(inkscape -z -f "$DIR/$TEMPLATE" -I $r -W)\
x$(inkscape -z -f "$DIR/$TEMPLATE" -I $r -H)\
+$(inkscape -z -f "$DIR/$TEMPLATE" -I $r -X)\
+$(inkscape -z -f "$DIR/$TEMPLATE" -I $r -Y)
	done
}


if [ ! -n "$(which adb)" ]
then
	echo "adb not present, using $DIR/screen.png" 1>&2
elif [ $(adb devices | grep -E "^[a-f0-9]{16}" | wc -l) -lt 1 ]
then
	echo "no device attached." 1>&2
else
	adb shell screencap -p > "$DIR/screen.png"
fi

# old extract method, but ImageMagick is faster than Inkscape
#inkscape -z -f "$(pwd)/template.svg" -i rectCP -e "$(pwd)/CP.png" 1>>/dev/null
#inkscape -z -f "$(pwd)/template.svg" -i rectHP -e "$(pwd)/HP.png" 1>>/dev/null
#inkscape -z -f "$(pwd)/template.svg" -i rectDust -e "$(pwd)/dust.png" 1>>/dev/null
#inkscape -z -f "$(pwd)/template.svg" -i rectPkmName -e "$(pwd)/pkmnName.png" 1>>/dev/null

CROPS_HEADER=$(head -n 1 $DIR/crops)
if [ ! -e "$DIR/crops" ] || [ "$CROPS_HEADER" != "$TEMPLATE" ]
then
	echo "generating $DIR/crops ..."
	init  > "$DIR/crops"
fi

#crop->grayscale->levels->negate


CP=$(convert "$IMG" -crop $(grep rectCP "$DIR/crops" | cut -d " " -f 2) -modulate 100,0 -level 99%,100% -negate png:- | tesseract -c tessedit_char_whitelist=cpCP0123456789 -psm 8 - - 2>>/dev/null | head -n 1 | grep -Eo "[0-9]+")
HP=$(convert $IMG -crop $(grep rectHP "$DIR/crops" | cut -d " " -f 2) png:- | tesseract -c tessedit_char_whitelist=HPV/0123456789 -psm 8 - - 2>>/dev/null | grep [a-zA-Z] | tr "oO" "00" | grep -Eo "/[0-9]+" | tr -d "/")
dust=$(convert $IMG -crop $(grep rectDust "$DIR/crops" | cut -d " " -f 2) png:- | tesseract -psm 8 - - digits 2>>/dev/null | head -n 1 | grep -Eo "[0-9]+")
pkmName=$(convert $IMG -crop $(grep rectPkmName "$DIR/crops" | cut -d " " -f 2) png:- | tesseract -psm 8 - - 2>>/dev/null | head -n 1 | tr "|" "l" | tr -d "0123456789+")
pkmID=$(grep -Ei ",$(echo "$pkmName" | sed "s/?/\\\?/g")($|,)" "$DIR/pkmns" | cut -d "," -f 1)

echo "$pkmName id:$pkmID cp:$CP hp:$HP dust:$dust"

URL="https://pokemon.gameinfo.io/en/tools/iv-calculator#$pkmID,$CP,$HP,$dust,1"

if [ -n "$(which xdg-open)" ]
then
	nohup xdg-open "$URL" 2>>/dev/null &
else
	open "$URL"
fi
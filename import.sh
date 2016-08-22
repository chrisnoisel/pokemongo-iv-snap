#!/bin/bash

DIR=$(dirname "$0")
IMG="$DIR/screen.png"

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

	for r in $rects
	do
		echo ">" $r 1>&2
		echo $r \
$(inkscape -z -f "$DIR/template.svg" -I $r -W)\
x$(inkscape -z -f "$DIR/template.svg" -I $r -H)\
+$(inkscape -z -f "$DIR/template.svg" -I $r -X)\
+$(inkscape -z -f "$DIR/template.svg" -I $r -Y)
	done
}

#####

if [ ! -n "$(which adb)" ]
then
	echo "adb not present, using $DIR/screen.png" 1>&2
elif [ $(adb devices | wc -l) -lt 3 ]
then
	echo "no device attached." 1>&2
else
	adb shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' > "$DIR/screen.png"
fi

# old extract method, but ImageMagick is faster than Inkscape
#inkscape -z -f "$(pwd)/template.svg" -i rectCP -e "$(pwd)/CP.png" 1>>/dev/null
#inkscape -z -f "$(pwd)/template.svg" -i rectHP -e "$(pwd)/HP.png" 1>>/dev/null
#inkscape -z -f "$(pwd)/template.svg" -i rectDust -e "$(pwd)/dust.png" 1>>/dev/null
#inkscape -z -f "$(pwd)/template.svg" -i rectPkmName -e "$(pwd)/pkmnName.png" 1>>/dev/null

if [ ! -e "$DIR/crops" ]
then
	echo "generating $DIR/crops ..."
	init  > "$DIR/crops"
fi

# crop -> grayscale -> levels -> negate
CP=$(convert "$IMG" -crop $(grep rectCP "$DIR/crops" | cut -d " " -f 2) -modulate 100,0 -level 95%,100% -negate png:- | tesseract -c tessedit_char_whitelist=CP0123456789 -psm 8 - - 2>>/dev/null | head -n 1 | tr "oO" "00" | grep -Eo "[0-9]+")

HP=$(convert $IMG -crop $(grep rectHP "$DIR/crops" | cut -d " " -f 2) png:- | tesseract -psm 8 - - 2>>/dev/null | grep HP  | tr "oO" "00" | grep -Eo "/[0-9]+" | tr -d "/")
dust=$(convert $IMG -crop $(grep rectDust "$DIR/crops" | cut -d " " -f 2) png:- | tesseract -psm 8 - - digits 2>>/dev/null | head -n 1 | tr "oO" "00" | grep -Eo "[0-9]+")
pkmName=$(convert $IMG -crop $(grep rectPkmName "$DIR/crops" | cut -d " " -f 2) png:- | tesseract -psm 8 - - 2>>/dev/null | head -n 1 | tr "|" "l" | tr -d " 0123456789+")
pkmID=$(grep -i " $pkmName$" "$DIR/pkmns" | cut -d " " -f 1)

echo "$pkmName id:$pkmID cp:$CP hp:$HP dust:$dust"

if [ -n "$(which iceweasel)" ]
then
	iceweasel "https://pokemon.gameinfo.io/tools/iv-calculator#$pkmID,$CP,$HP,$dust,1" 2>>/dev/null
elif [ -x /Applications/Chromium.app/Contents/MacOS/Chromium ]
then
	/Applications/Chromium.app/Contents/MacOS/Chromium "https://pokemon.gameinfo.io/tools/iv-calculator#$pkmID,$CP,$HP,$dust,1"
else
	echo "https://pokemon.gameinfo.io/tools/iv-calculator#$pkmID,$CP,$HP,$dust,1"
fi

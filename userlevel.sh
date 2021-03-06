#!/bin/bash

TEMPLATE="template.svg"

CPM="0.094 0.1351374 0.1663979 0.1926509 0.2157325 0.2365727 0.2557201 0.2735304 0.2902499 0.3060574 0.3210876 0.335445 0.3492127 0.3624578 0.3752356 0.3875924 0.3995673 0.4111936 0.4225 0.4335117 0.4431076 0.45306 0.4627984 0.4723361 0.481685 0.4908558 0.4998584 0.5087018 0.517394 0.5259425 0.5343543 0.5426358 0.5507927 0.5588306 0.5667545 0.5745692 0.5822789 0.5898879 0.5974 0.6048188 0.6121573 0.6194041 0.6265671 0.6336492 0.640653 0.647581 0.6544356 0.6612193 0.667934 0.6745819 0.6811649 0.6876849 0.6941437 0.7005429 0.7068842 0.7131691 0.7193991 0.7255756 0.7317 0.734741 0.7377695 0.7407856 0.7437894 0.7467812 0.749761 0.7527291 0.7556855 0.7586304 0.7615638 0.7644861 0.7673972 0.7702973 0.7731865 0.776065 0.7789328 0.7817901 0.784637 0.7874736 0.7903 0.7931164"

function cpm
{
	if [ -n $1 ]
	then
		echo "$CPM" | cut -d " " -f $(echo "$1 * 2 - 1" | bc | grep -Eo "^[0-9]+")
	fi
}


if [ -z "$1" ]
then
	echo "usage: $0 <trainer level> [template path]" >&2
	exit 1
fi

if [ -e "$2" ]
then
	TEMPLATE="$2"
	echo "USING $TEMPLATE" >&2
fi

lvl=$1

sed -i '/anchor1/,/anchor2/{//!d}' "$TEMPLATE"
sed -r -i "s/Trainer level : [0-9]+/Trainer level : $lvl/" "$TEMPLATE"

tpl='    <rect
       style="fill:none;fill-opacity:1;stroke:#ffffff;stroke-width:6;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
       id="rectarc3428"
       width="468.41171"
       height="268.36087"
       x="253.72301"
       y="258.60226" />'

out=""

iw=$(grep -C 4 image4580 "$TEMPLATE" | grep height | grep -Eo "[0-9]+")
cx=$(echo "($(grep -B 3 'arc_left' $TEMPLATE | grep position | grep -Eo '[0123456789.,]+' | cut -d , -f 1)\
+$(grep -B 3 'arc_right' $TEMPLATE | grep position | grep -Eo '[0123456789.,]+' | cut -d , -f 1))/2" | bc -l)
cr=$(echo "($(grep -B 3 'arc_right' $TEMPLATE | grep position | grep -Eo '[0123456789.,]+' | cut -d , -f 1)\
-$(grep -B 3 'arc_left' $TEMPLATE | grep position | grep -Eo '[0123456789.,]+' | cut -d , -f 1))/2" | bc -l)
cy=$(echo "$iw-$(grep -B 3 'arc_bottom' $TEMPLATE | grep position | grep -Eo '[0123456789.,]+' | cut -d , -f 2)" | bc -l)

#echo $cx $cr $cy

l=1
while [ $l -le $(( $lvl + 2 )) ]
do
	cpmMin=$(cpm 1)
	cpmMax=$(cpm $(( $lvl + 2 )))
	cpmI=$(cpm $l)
	
	a=$(echo "3.141592 * ($cpmI - $cpmMin) / ($cpmMax - $cpmMin)" | bc -l)
	
	len=30
	if [ $(( $l % 10 )) == 0 ]
	then
		len=90
	elif [ $(( $l % 5 )) == 0 ]
	then
		len=60
	fi
	
	x=$(echo "$cx - c($a) * $cr" | bc -l)
	y=$(echo "$cy + c($a + 3.141592/2) * $cr" | bc -l)
	w=$(echo "c($a) * $len" | bc -l)
	h=$(echo "-c($a + 3.141592/2) * $len" | bc -l)
	
	out="$out"'
    <path
       style="fill:none;fill-rule:evenodd;stroke:#ffffff;stroke-width:6;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:0.7"
       d="m '$x','$y' '$w','$h'"
       id="path3427"
       inkscape:connector-curvature="0" />'
	
	l=$(($l + 1))
done

echo "$(sed '/anchor1/q' $TEMPLATE)"$'\n'"$out"$'\n'"$(sed '0,/anchor1/d' $TEMPLATE)" > "$TEMPLATE"

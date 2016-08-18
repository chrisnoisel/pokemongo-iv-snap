#!/bin/bash

lvl=$1

sed -i '/anchor1/,/anchor2/{//!d}' template.svg

tpl='    <rect
       style="fill:none;fill-opacity:1;stroke:#ffffff;stroke-width:6;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
       id="rectarc3428"
       width="468.41171"
       height="268.36087"
       x="253.72301"
       y="258.60226" />'

out=""

ca="52357.9848"
cb="1337.885703"

l=1
while [ $l -le $lvl ]
do

	a=$(echo "(sqrt( (($l-1)/($lvl + 3)) * $ca + $cb) - sqrt($cb)) * 3.141592 / 180.0 " | bc -l)
	
	#echo "($l-1)/($lvl + 3)" | bc -l
	#echo "sqrt( (($l-1)/($lvl + 3)) * $ca + $cb) - sqrt($cb)" | bc -l
	#echo ""
	
	len=30
	if [ $(( $l % 10 )) == 0 ]
	then
		len=90
	elif [ $(( $l % 5 )) == 0 ]
	then
		len=60
	fi
	
	x=$(echo "538 - c($a) * 408" | bc -l)
	y=$(echo "640.82 + c($a + 3.141592/2) * 408" | bc -l)
	w=$(echo "c($a) * $len" | bc -l)
	h=$(echo "-c($a + 3.141592/2) * $len" | bc -l)
	
	out="$out"'
    <path
       style="fill:none;fill-rule:evenodd;stroke:#ffffff;stroke-width:12;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:0.7"
       d="m '$x','$y' '$w','$h'"
       id="path3427"
       inkscape:connector-curvature="0" />'
	
	l=$(($l + 1))
done

echo "$(sed '/anchor1/q' template.svg)"$'\n'"$out"$'\n'"$(sed '0,/anchor1/d' template.svg)" > template.svg
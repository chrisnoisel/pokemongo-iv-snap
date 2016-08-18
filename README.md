# pokemongo-iv-snap
Grab pokemon data on an android device, no MITM involved, probably ToS compliant :p

This script takes a screenshot on a connected Android phone (thanks to adb, works through USB or wifi !), extracts the data with tesseract, displays the possible IVs (iceweasel), the pokemon level can also be determined with ./template.svg
You may need to adapt the script to match your setup, currently it works fine on linux and partially on osx.

Works with the english version of the game (pokemon names change with language) but you can edit or replace the ./pkmns file if needed.
A few pokemon animations (like Gastly) tends to mask the CP value, so tesseract might not work properly in thoses cases.

use :
* ./userlevel.sh <your user level> : automatically edits template.svg to display the units on the pokemon level arc.
* ./import.sh : does the main job

files :
* template.svg : display an overlay on the screenshot to show the pokemon's level. Currenty there is a an increasingly error offset as the user level goes up, more maths are needed to get a perfect match. This files also defines the areas where the useful bits of information need to be extracted. My phone screen is 1080x1920, you might need to adjust (Inkscape) if yours is different.
* crops : contains the coordinates of the area containing the relevant info, automatically generated by import.sh from template.sh if the file is not present.
* pkmns : links a pokemon name with its id, you may provide several names for a same id, useful to work with different languages or provide workarounds with tesseract not able to detect some caracters (like "Nidoran♂" read as "Nidorand")
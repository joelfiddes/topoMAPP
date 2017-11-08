#!/bin/bash
startDate=$1
endDate=$2
options_file=$3
out_wd=$4

# bbox=$longWest,$latSouth,$longEast,$latNorth
# startElement='"bbox": ['
# endElement='],'
# newPar=$startElement$bbox$endElement
# oldParN=$(grep -n 'bbox' $options_file | awk -F: '{print $1}')
# lineNo=$oldParN
# var=$newPar
# sed -i "${lineNo}s/.*/$var/" $options_file

#update startdate
findElement='"start_date":'
newPar=$findElement'"'$startDate'",'
oldParN=$(grep -n $findElement $options_file | awk -F: '{print $1}')
lineNo=$oldParN
var=$newPar
sed -i "${lineNo}s/.*/$var/" $options_file

#update enddate
findElement='"end_date":'
newPar=$findElement'"'$endDate'",'
oldParN=$(grep -n $findElement $options_file | awk -F: '{print $1}')
lineNo=$oldParN
var=$newPar
sed -i "${lineNo}s/.*/$var/" $options_file

#update write dir - | delim used to prevent clash with file path in $var under variable expansion
findElement='"out_folder":'
newPar=$findElement'"'$out_wd'",'
oldParN=$(grep -n $findElement $options_file | awk -F: '{print $1}')
lineNo=$oldParN
var=$newPar
sed -i "${lineNo}s|.*|$var|" $options_file

#update write dir2 =- | delim used to prevent clash with file path in $var under variable expansion
findElement='"out_folder_mod":'
newPar=$findElement'"'$out_wd'",'
oldParN=$(grep -n $findElement $options_file | awk -F: '{print $1}')
lineNo=$oldParN
var=$newPar
sed -i "${lineNo}s|.*|$var|" $options_file

#===== hack until MODIStsp defines tiles by bbox

# findElement='"start_x":'
# newPar=$findElement'"'$xstart'",'
# oldParN=$(grep -n $findElement $options_file | awk -F: '{print $1}')
# lineNo=$oldParN
# var=$newPar
# sed -i "${lineNo}s|.*|$var|" $options_file

# findElement='"end_x":'
# newPar=$findElement'"'$xend'",'
# oldParN=$(grep -n $findElement $options_file | awk -F: '{print $1}')
# lineNo=$oldParN
# var=$newPar
# sed -i "${lineNo}s|.*|$var|" $options_file

# findElement='"start_y":'
# newPar=$findElement'"'$ystart'",'
# oldParN=$(grep -n $findElement $options_file | awk -F: '{print $1}')
# lineNo=$oldParN
# var=$newPar
# sed -i "${lineNo}s|.*|$var|" $options_file

# findElement='"end_y":'
# newPar=$findElement'"'$yend'",'
# oldParN=$(grep -n $findElement $options_file | awk -F: '{print $1}')
# lineNo=$oldParN
# var=$newPar
# sed -i "${lineNo}s|.*|$var|" $options_file
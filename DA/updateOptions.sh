#!/bin/bash

# Update bbox
longWest=$1
latSouth=$2
longEast=$3
latNorth=$4
startDate=$5
endDate=$6
options_file=$7
sca_wd=$8


bbox=$longWest,$latSouth,$longEast,$latNorth
startElement='"bbox": ['
endElement='],'
newPar=$startElement$bbox$endElement
oldParN=$(grep -n 'bbox' $options_file | awk -F: '{print $1}')
lineNo=$oldParN
var=$newPar
sed -i "${lineNo}s/.*/$var/" $options_file

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
newPar=$findElement'"'$sca_wd'",'
oldParN=$(grep -n $findElement $options_file | awk -F: '{print $1}')
lineNo=$oldParN
var=$newPar
sed -i "${lineNo}s|.*|$var|" $options_file

#update write dir2 =- | delim used to prevent clash with file path in $var under variable expansion
findElement='"out_folder_mod":'
newPar=$findElement'"'$sca_wd'",'
oldParN=$(grep -n $findElement $options_file | awk -F: '{print $1}')
lineNo=$oldParN
var=$newPar
sed -i "${lineNo}s|.*|$var|" $options_file

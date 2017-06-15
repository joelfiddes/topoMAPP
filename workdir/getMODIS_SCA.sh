# #https://github.com/lbusett/MODIStsp
# use to set params: "Rscript getMODIS_SCA.R TRUE $options_file"
# docs MÒDIS SCA https://modis-snow-ice.gsfc.nasa.gov/uploads/C6_MODIS_Snow_User_Guide.pdf
# Sript gets extent from DEM and sets options for SCA download

source $wd/toposat.ini
gui=$1 #TRUE or FALSE

# clear data
#rm -r $sca_wd/*

# compute from dem
longWest=$(Rscript getExtent.R $wd/predictors/ele.tif lonW)
longEast=$(Rscript getExtent.R $wd/predictors/ele.tif lonE)
latNorth=$(Rscript getExtent.R $wd/predictors/ele.tif latN)
latSouth=$(Rscript getExtent.R $wd/predictors/ele.tif latS)
startDate=$startDate # from main pars
endDate=$endDate #from main pars

# Update bbox
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

# run MODIStsp tool
Rscript getMODIS_SCA.R $gui $options_file # cannot run non-interactively for some reason

# extract timersies per point
Rscript extractSCATimeseries.R $wd $sca_wd'/Snow_Cov_Daily_500m_v5/SC' $wd'/spatial/points.shp' 
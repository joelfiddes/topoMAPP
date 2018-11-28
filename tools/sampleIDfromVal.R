# takes landform and spatial points (fullpath) as input and returns Sample IDS

#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)

#SOURCE
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
points=args[2]


lf= raster(paste0(wd,"/landform.tif"))
shp = shapefile(points)
shpids = shp[[1]]

IDS = extract(lf, shp)
IDS.IND = which(!is.na(IDS))
shpids2 = shpids[IDS.IND]
IDS2 = na.omit(extract(lf, shp))
long = formatC(IDS2, flag="0", width=5)
paths = paste0(shpids2,"/S",long)
cat((paths))
 
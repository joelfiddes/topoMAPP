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
#IDS = extract(lf, shp)
IDS = na.omit(extract(lf, shp))
long = formatC(IDS, flag="0", width=5)
paths = paste0(wd,"S",long)
cat((paths))
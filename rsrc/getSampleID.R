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
landform=args[1]
points=args[2]

lf= raster(landform)
shp = shapefile(points)
IDS = extract(lf, shp)
cat(as.numeric(IDS))
#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)
require(sp)

#SOURCE
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
n=as.numeric(args[1])
s=as.numeric(args[2])
e=as.numeric(args[3])
w=as.numeric(args[4])
out=args[5]

e <- as(raster::extent(e, w, s, n), "SpatialPolygons")
proj4string(e) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
shapefile(e, out)
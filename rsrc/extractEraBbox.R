
# ERA box are defined at their centres (7.5, 46.5)
 # This function takes user defined coords as input and return nearest (outer) era-grid boundary

# example call makeBbox.R '/home/joel/src/TOPOMAP/toposubv2/topoMAPP/dat/eraigrid75.tif' ,'lonW',9,10,45,46

args = commandArgs(trailingOnly=TRUE)
file=args[1] # 0.25 0r 0.75 era grid fullpath
coordID=args[2] # id of coord eg lonW lonE latS latN
lonw=as.numeric(args[3]) # value of coord eg '9'
lone=as.numeric(args[4])
lats=as.numeric(args[5])
latn=as.numeric(args[6])

require(raster)
rst=raster(file)
library(sp)
e <- as(raster::extent(lonw, lone, lats, latn), "SpatialPolygons")
proj4string(e) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
ext=extent(crop(rst,e, snap='out'))

if (coordID=='lonW'){cat(as.numeric(ext@xmin))}
if (coordID=='lonE'){cat(as.numeric(ext@xmax))}
if (coordID=='latN'){cat(as.numeric(ext@ymax))}
if (coordID=='latS'){cat(as.numeric(ext@ymin))}




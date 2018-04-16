#====================================================================
# SETUP
#====================================================================
#INFO
# NOW not used getGridEle.R which had bug as used ful era extrent downloaded NOT cropped one

#DEPENDENCY
require(raster)

#SOURCE

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
dem=args[2]
eraExtent=args[3]
#====================================================================
# PARAMETERS FIXED
#====================================================================

#**********************  SCRIPT BEGIN *******************************
setwd(wd)
d=raster(dem)
x=raster(eraExtent)
gridBoxRst=init(x, v='cell')
poly=rasterToPolygons(gridBoxRst)
demc=crop(d,poly)
boxEle=extract(demc, poly,mean)
write.table(boxEle, 'eraEle.txt', sep=',', row.names=FALSE, col.names=FALSE)
#cat(as.numeric(boxEle))
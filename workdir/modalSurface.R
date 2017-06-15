#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1] #'/home/joel/sim/topomap_test/grid1' #

#====================================================================
# PARAMETERS FIXED
#====================================================================
#**********************  SCRIPT BEGIN *******************************
setwd(wd)

#get modal surface type of each sample 0=vegetation, 1=debris, 2=steep bedrock
lc=raster('predictors/surface.tif')
zones=raster('landform.tif')
zoneStats=zonal(lc,zones, modal,na.rm=T)
write.table(zoneStats,'landcoverZones.txt',sep=',', row.names=F)
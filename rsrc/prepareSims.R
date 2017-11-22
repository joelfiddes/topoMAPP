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
wd= args[1]
#====================================================================
# PARAMETERS FIXED
#====================================================================

#**********************  SCRIPT BEGIN *******************************
setwd(wd)
eraExtent=raster(paste0(wd,'/spatial/eraExtent.tif'))
Nruns=ncell(eraExtent)
r=setValues(eraExtent,1:Nruns)
extentPoly=rasterToPolygons(r)

for (i in 1:Nruns){
setwd(wd)
dir.create(paste0('grid',i), showWarnings=FALSE)
dir.create(paste0('grid',i,'/predictors'), showWarnings=FALSE)
setwd(paste0(wd,'/predictors'))
predictors=list.files(pattern='*.tif$')
Npreds=length(predictors)

	for (p in 1:Npreds){
	setwd(paste0(wd,'/predictors'))	
	crop(raster(predictors[p]) ,extentPoly[extentPoly$eraExtent==i,], filename = paste0( wd, '/grid', i,'/predictors/' , predictors[p] ) , overwrite=TRUE)
	#rst=crop(raster(predictors[p]) ,extentPoly[extentPoly$eraExtent==i,])
	#setwd(paste0(wd, '/grid', i,'/predictors'))
	#writeRaster(rst, predictors[p], overwrite=TRUE)
	}
}
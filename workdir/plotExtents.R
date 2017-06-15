#====================================================================
# SETUP
#====================================================================
#INFO

#plot retrieved era against dem to check extents

#DEPENDENCY
require(raster)

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
 #'/home/joel/sim/topomap_test/grid1' #
wd=args[1]
#====================================================================
# PARAMETERS FIXED
#====================================================================\
setwd(wd)
#plot of simulation domain
pdf('spatial/extentEraMap.pdf')
plot(raster('predictors/ele.tif'), main='Retrieved extent of ERA-grids overlaid DEM.' , sub='ERA-grid outline (blue). ele.tif (raster)')
plot(extent(raster('eraDat/SURF.nc')),add=TRUE, col='blue', lwd=3)
dev.off()






    
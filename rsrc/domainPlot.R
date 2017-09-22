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
wd=args[1]
plotshp=args[2]

setwd(wd)


eraExtent=raster('spatial/eraExtent.tif')
dem=raster('predictors/ele.tif')

#plot of simulation domain
pdf('spatial/extentMap.pdf')
#plot(extent(eraExtent),col='green', lwd=2, main='New extent of ERA-grids overlaid input DEM.' , sub='ERA request (green), points (red)')
plot(rasterToPolygons(eraExtent),border='green', lwd=2, main='New extent of ERA-grids overlaid input DEM.' , sub='ERA request (green), points (red)')
plot(dem,add=TRUE, lwd=2)
plot(rasterToPolygons(eraExtent),border='green', lwd=2, main='New extent of ERA-grids overlaid input DEM.' , sub='ERA request (green), points (red)') # replot on top

if(plotshp==TRUE){
	shp = shapefile('spatial/points.shp')
plot(shp,add=TRUE, cex=2, col='red')
#text(shp[,2],shp[,3],shp[,1])
}
dev.off()




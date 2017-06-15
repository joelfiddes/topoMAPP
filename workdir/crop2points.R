#====================================================================
# SETUP
#====================================================================
#INFO
#account required https://urs.earthdata.nasa.gov/profile

#DEPENDENCY
require(raster)

#SOURCE


#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
setwd(wd)
# crop
rst=raster('predictors/ele.tif')
shp=shapefile('spatial/points.shp')
ele=crop(rst, extent(shp)+0.05,snap='out') # includes a buffer to allow for topo computations
writeRaster(ele, 'predictors/ele.tif', overwrite=TRUE)
print('crop2points complete')


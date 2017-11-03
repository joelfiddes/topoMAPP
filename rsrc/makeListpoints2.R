#====================================================================
# SETUP
#====================================================================
#INFO
# A listpoints file has pk, lon, lat order of cols

#DEPENDENCY
require(raster)

#SOURCE

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1] 
shp.in=args[2]

#====================================================================
# PARAMETERS FIXED
#====================================================================

setwd(paste0(wd,'/predictors'))
predictors=list.files( pattern='*.tif$')
print(predictors)
rstack=stack(predictors)
shp <- shapefile(shp.in)
lp = extract(rstack,shp)
lon = shp@coords[,1]
lat = shp@coords[,2]
pk= 1:length(lat)
lp = data.frame(pk,lp, lon,lat)
lp = na.omit(lp)
write.csv(lp, '../listpoints.txt', row.names=FALSE)

# Test if grid contains points and remove if not
library(rgeos)
raster <- rstack
poly  = shp
  ei <- as(extent(raster), "SpatialPolygons")
  if (gContainsProperly(poly, ei)) {
    print ("Grid contains points")
  } else if (gIntersects(poly, ei)) {
    print ("intersects")
  } else {
    print ("Grid contains no points, removing grid directory")
    system(paste0('rm -r ', wd))
  }

#Ensure grid names sequential

# compute svf for each point efficiently
#ele=raster('ele.tif')
#e <- extract(ele, shp, buffer=0.1)
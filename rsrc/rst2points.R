#You can use this to make a shapefile of your raster cells. just need to specify these variable:
library(raster)

path2rst <- "~/myraster.tif"
outDir <- "~/myshape.shp"

#define function
makePointShapeGeneriRc=function(lon,lat,data,proj='+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'){
library(raster)
library(rgdal)
loc<-data.frame(lon, lat)
spoints<-SpatialPointsDataFrame(loc,as.data.frame(data), proj4string= CRS(proj))
return(spoints)
}

# read raster
rst = raster(path2raster)

# get matrix from rst
points = rasterToPoints(rst)

# make shape
shp = makePointShapeGeneriRc(lon = points[,1], lat = points[,2], data = points[,3])

# write out
shapefile(shp, outDir)




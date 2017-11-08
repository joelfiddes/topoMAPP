# converts raster to shapefile extent
require(raster)
args = commandArgs(trailingOnly=TRUE)
rstin = args[1] #"/home/joel/src/topoMAPP/dat/eraigrid75.tif"
outpath= args[2]

# import raster
rst = raster(rstin)
# get extent
e <- extent(rst)

# convert to spatial polygons
shp <- as(e, 'SpatialPolygons') 

# assign corect projcetion
crs(shp) <- crs(rst)

# write out shp
shapefile(shp, outpath, overwrite=TRUE)
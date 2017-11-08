require(raster)
# era5 grid
rst = raster("/home/joel/src/topoMAPP/dat/era5grid30.tif")

# eraI grid
#rst = raster("/home/joel/src/topoMAPP/dat/eraigrid75.tif")

#===============================================================================
# use case #1: single point
#===============================================================================
# singlepoint shape
p=shapefile("/home/joel/data/GCOS/wfj.shp")

# cell corresponding to point
ncell = cellFromXY(rst, p)

# extract that cell
r2 <- rasterFromCells(rst, ncell, values=TRUE)

# extent of era gridcells covered by AOI
eraExtent=extent(r2)

# extent in whole degrees for dem download to completely cover eragrid cell
demExtent = floor(eraExtent)

plot(demExtent)
plot(eraExtent, add=T, col='blue')
plot(p, add=T)


#===============================================================================
# use case #2: multiple point
#===============================================================================

# multipoint shape
p=shapefile("/home/joel/data/GCOS/metadata_easy.shp")

# cell corresponding to point
ncell = cellFromXY(rst, p)

# extract that cell
r2 <- rasterFromCells(rst, ncell, values=TRUE)

# extent of era gridcells covered by AOI
eraExtent=extent(r2)

# extent in whole degrees for dem download to completely cover eragrid cell
demExtent = floor(eraExtent)

plot(demExtent)
plot(eraExtent, add=T, col='blue')
plot(p, add=T)

#===============================================================================
# use case #3:grid: extractEraBbox.R
#===============================================================================
lonw= 9.7
lone = 9.9
latn = 46.9
lats = 46.7

e <- as(raster::extent(lonw, lone, lats, latn), "SpatialPolygons")
proj4string(e) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"

# extent of era gridcells covered by AOI
eraExtent=extent(crop(rst,e, snap='out'))

# extent in whole degrees for dem download to completely cover eragrid cell
demExtent = floor(eraExtent)

plot(demExtent)
plot(eraExtent, add=T, col='blue')
plot(e, add=T, col='red')

# find which grid cells actually contain points

require(raster)

args = commandArgs(trailingOnly=TRUE)
rst <- arg[1]raster("/home/joel/sim/test_points/spatial/eraExtent.tif")
shp  = arg[2] # shapefile("/home/joel/data/imis/gis/IMIS_GR.shp")

# replace values 1: ncell this is the grids index
values(rst)<- 1:ncell(rst)
ids = sort(unique(extract(rst,shp)))
gridsout <- paste0("grid", ids)
cat(gridsout)


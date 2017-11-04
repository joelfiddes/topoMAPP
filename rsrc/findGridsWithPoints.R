# find which grid cells actually contain points

require(raster)

args = commandArgs(trailingOnly=TRUE)

wd<- args[1] 
rstin <- args[2] # raster("/home/joel/sim/test_points/spatial/eraExtent.tif")
shpin  <- args[3] # shapefile("/home/joel/data/imis/gis/IMIS_GR.shp")

rst <- raster(rstin)
shp <- shapefile(shpin)
# replace values 1: ncell this is the grids index
values(rst)<- 1:ncell(rst)
ids = sort(unique(extract(rst,shp)))
gridsout <- paste0(wd,"/grid", ids)
cat(gridsout)


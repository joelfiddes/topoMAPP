# extracts time series at given locations (shapefile) for validation against obs

#====================================================================
# PARAMETERS/ARGS
#====================================================================
# sim="/home/joel/mnt/nas/sim/SIMS_JAN18/gcos_era5/grid8"
# SHPNAME="/home/joel/stations_box.shp" 
# param = "Tair.C." 
# file="surface.txt"

getValTimeries = function(sim, shpname, param,file) {

require(raster)

shp = shapefile(shpname)
rst=raster(paste0(sim,'/landform.tif'))
cp <- as(extent(rst), "SpatialPolygons")

valpoints=extract(rst,shp)
valIndex=which(is.na(valpoints)==FALSE)


tseries.mat=c()
for ( i in valpoints) {

	id = formatC(valpoints[1],flag="0", width=5)
	simdir = paste0(sim,"/S", id )
	dat = read.csv(paste0(simdir, "/out/",file))
 	tseries = dat[param]
 	tseries.mat=cbind(tseries.mat, tseries[,1])
}

return(tseries.mat)
}
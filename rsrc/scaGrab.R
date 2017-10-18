# helper function that takes existing 
require(raster)
dir = "/home/joel/sim/scale_test_sml/SC"
lpath = "/home/joel/sim/test_radflux/grid2/"

files <- list.files(path=dir,full.names = TRUE, pattern = "\\.tif$")
rstack = stack(files)

lf=raster(paste0(lpath, "/landform.tif"))
rstack.crop <- crop(rstack, lf)
 
out=paste0(lpath, "MODIS/SC/Snow_Cov_Daily_500m_v5/SC/import/")


writeRaster(rstack.crop, paste0(out,names(rstack.crop)), bylayer=TRUE, format='GTiff')




t1=Sys.time()
rstack = stack(files[1:10])
rstack.crop <- crop(rstack, lf)
t2=Sys.time() -t1
t2

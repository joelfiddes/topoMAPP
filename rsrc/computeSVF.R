args = commandArgs(trailingOnly=TRUE)
gridpath = args[1]
angles = args[2]
dist = args[3]

require(horizon)

ele=raster(paste0(wd, "/predictors/ele.tif"))
s <- svf(ele, nAngles=6, maxDist=500, ll=TRUE)
setwd(paste0(wd,'/predictors'))
writeRaster(round(s,2), paste0(wd, "/predictors/svf.tif"), overwrite=TRUE) #write and reduce precision


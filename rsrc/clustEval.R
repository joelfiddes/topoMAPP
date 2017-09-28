#evaluate clusting
require(raster)

rmse <- function(error)
{
    sqrt(mean(error^2, na.rm=TRUE))
}


wd = "/home/joel/sim/da_test2/grid1/"
p = "/home/joel/data/GCOS/metadata_easy.shp"
landform = raster(paste0(wd,"landform.tif"))
ele = raster(paste0(wd, "predictors/ele.tif"))
slp = raster(paste0(wd, "predictors/slp.tif"))
asp = raster(paste0(wd, "predictors/asp.tif"))
lp = read.csv(paste0(wd, "listpoints.txt"))

# domain wide eveal
eleRst = subs(landform, lp[,c(2,3)])
eleVal = ele-eleRst
hist(eleVal)
vals=getValues(eleVal)
mean(vals,na.rm=T)
sd(vals,na.rm=T)
rmse(vals)

# eval at certain points
point= shapefile(p)
extract(eleVal, point)

# evaluate forcing


#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(ncdf4)
require(raster)
#SOURCE
source('./rsrc/tscale_src.R')
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]

#====================================================================
# PARAMETERS FIXED
#====================================================================
file = paste0(wd,'/eraDat/SURF.nc')
eraExtent = raster(paste0(wd,"/spatial/eraExtent.tif"))

#get extent
r=raster(file)
#**********************  SCRIPT BEGIN *******************************
setwd(wd)
nc=nc_open(file)
gp = ncvar_get( nc,'z')
surfEle = gp[,, 1] / 9.80665

# assign these values to containt "r" on 
r2 =setValues(r, as.vector(surfEle))

# crop by actual extent
r3 = crop(r2, eraExtent)
ele = getValues(r3)

#ele=as.vector(surfEle)
grid=1:length(ele)

# construct dataframe
df=data.frame(grid, ele)
write.table(ele, 'eraEle.txt', sep=',', row.names=FALSE, col.names=FALSE)


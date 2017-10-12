#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(ncdf4)
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
#**********************  SCRIPT BEGIN *******************************
setwd(wd)
nc=nc_open(file)
gp = ncvar_get( nc,'z')
surfEle = gp[,, 1] / 9.80665

ele=as.vector(surfEle)
grid=1:length(surfEle)

# construct dataframe
df=data.frame(grid, ele)
write.table(ele, 'eraEle.txt', sep=',', row.names=FALSE, col.names=FALSE)


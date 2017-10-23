#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)
require(horizon)
#SOURCE


#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
svfComp=args[2]
#====================================================================
# PARAMETERS FIXED
#====================================================================
rasterOptions(tmpdir=wd)
#**********************  SCRIPT BEGIN *******************************
setwd(wd)
dem=raster('predictors/ele.tif')

#====================================================================
# EXTRACT SVF
#====================================================================
#https://cran.r-project.org/web/packages/horizon/horizon.pdf
#http://onlinelibrary.wiley.com/doi/10.1002/joc.3523/pdf

# this doesnt scale - now implemented in Ngrid loop as separate module for scalability
#if (svfComp == TRUE){
#	print("Warning: computing svf which can take some time")
#r <- dem
#s <- svf(r, nAngles=6, maxDist=500, ll=TRUE)

#setwd(paste0(wd,'/predictors'))
#writeRaster(round(s,2), "svf.tif", overwrite=TRUE) #write and reduce precision

#}
#perhaps need to do this on indiv tiles for memory issues?

#====================================================================
# EXTRACT SLP/ASP
#================================================================= ==
slp=terrain(dem, opt="slope", unit="degrees", neighbors=8, filename='')
asp=terrain(dem, opt="aspect", unit="degrees", neighbors=8, filename='')

#====================================================================
# WRITE OUTPUTS
#====================================================================
setwd(paste0(wd,'/predictors'))
writeRaster(round(slp,0), "slp.tif", overwrite=TRUE) #write and reduce precision
writeRaster(round(asp,0), "asp.tif", overwrite=TRUE) #write and reduce precision



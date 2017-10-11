#====================================================================
# SETUP
#====================================================================
#INFO
#make horizon files MOVED TO SEPERATE SCRISPT
#hor(listPath=wd)
#MODISoptions() controls settings

#DEPENDENCY
#require('MODIS') # https://cran.r-project.org/web/packages/MODIS/MODIS.pdf
require('rgdal') #dont understand why need to load this manually
require(raster)
#SOURCE
#source("/home/joel/src/TOPOMAP/toposubv2/workdir/toposub_src.R")

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
modPath =args[2]#given in MODISoptions()




#====================================================================
# PARAMETERS FIXED
#====================================================================


#PARAMETERS TO BOECKLI 2012 SLOPE MODEL
smin=35
smax=55
#introduce parameter for debris/bedrock class split

#threshold to distinguish between veg and non-veg
ndviThreshold=0.4 

#**********************  SCRIPT BEGIN *******************************
setwd(wd)


#====================================================================
#	fetch and compute MODIS NDVI
#====================================================================

myextent=raster('predictors/ele.tif') # output is projected and clipped to this extent

setwd(modPath)
modStack=stack(list.files(pattern='*.tif$', recursive = TRUE))
print("The following rasterStack will be used to compute average NDVI:")
print(modStack)

meanNDVI = mean(modStack, na.rm=TRUE)*0.0001 #mean of 5 periods plus scaling factor to make 0-1 NDVI value

print(paste0("grid mean= " , cellStats(meanNDVI, 'mean')))
print(paste0("grid sd= " ,cellStats(meanNDVI, 'sd')))
#classify
from=c(0, ndviThreshold)
to=c(ndviThreshold, 1)
becomes=c(0,1)
rcl= data.frame(from, to, becomes)
meanNDVIReclass = reclassify(meanNDVI, rcl) #1=veg 0=no veg
#====================================================================
#	compute bedrock debris slope model (Boeckli 2012)
#====================================================================
setwd(wd)

slp=raster('predictors/slp.tif')
slpModel = calc(slp, fun=function(x){(x - smin) / (smax-smin)})

#crisp classes ie split by 45 degree slope
from=c(-9999, 0.5)
to=c(0.5, 9999)
becomes=c(1,2)
rcl= data.frame(from, to, becomes)
slpModelReclass = reclassify(slpModel, rcl)

#====================================================================
#	combine rock model and veg map
#====================================================================
subsdf=data.frame(1,0)
reclassVeg=subs(x=meanNDVIReclass,  y=subsdf, by=1, which=2, subsWithNA=TRUE) #values 1 (veg) become 2 , values 0 (no veg) become NA


surf=resample(reclassVeg, slpModelReclass, method='ngb')

surfaceModel=cover(surf, slpModelReclass) #0= veg, 1=debris , 2=steep bedrock

#====================================================================
#	output
#====================================================================

writeRaster(surfaceModel, 'predictors/surface.tif', overwrite=TRUE)

pdf('surfaceClassMap.pdf', width=6, height =12)
par(mfrow=c(2,1))
arg <- list(at=seq(0,2,1), labels=c("Vegetation (0)","Debris (1)","Steep bedrock (2)")) #these are the class names
color=c("lightgreen","grey","red") #and color representation
plot(surfaceModel, col=color, axis.arg=arg, main='Surface class distribution')
hist(surfaceModel, main='Surface class frequency')
dev.off()

#====================================================================
#	zonal stats
#====================================================================

# zones=raster('landform.tif')
# zoneStats=zonal(surfaceModel,zones, modal,na.rm=T)
# write.table(zoneStats, 'landcoverZones.txt',sep=',', row.names=F)
# print(zoneStats)

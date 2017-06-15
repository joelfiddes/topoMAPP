#====================================================================
# SETUP
#====================================================================
#INFO
#make horizon files MOVED TO SEPERATE SCRISPT
#hor(listPath=wd)


#DEPENDENCY
require('MODIS') # https://cran.r-project.org/web/packages/MODIS/MODIS.pdf
require('rgdal') #dont understand why need to load this manually

#SOURCE
#source("/home/joel/src/TOPOMAP/toposubv2/workdir/toposub_src.R")

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
outDirPath =args[2]#given in MODISoptions()
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


#getProduct() #identify products to download
myextent=raster('predictors/ele.tif') # output is projected and clipped to this extent

#getSds(HdfName='/home/joel/data/MODIS_ARC/MODIS/MOD13Q1.005/2000.08.12/MOD13Q1.A2000225.h25v06.005.2006307225438.hdf', SDSstring="250m 16 days NDVI") # incorrect result



mydates=c("2000-08-12", "2004-08-12","2008-08-12","2012-08-12","2016-08-12")
	for (mydate in mydates){
	print (paste0('computing NDVI for ', mydate))	
	runGdal(product='MOD13Q1', collection = NULL, begin = mydate, end = mydate, extent = myextent, tileH = NULL, tileV = NULL, buffer = 0,SDSstring = "1 0 0 0 0 0 0 0 0 0 0 0", job = NULL, checkIntegrity = TRUE, wait = 0.5, forceDownload = TRUE, overwrite = FALSE)
	}
#scale product by 0.0001 to get 0-1

setwd(outDirPath)
modStack=stack(list.files(pattern='*.tif$', recursive = TRUE))
print("The following rasterStack will be used to compute avergae NDVI:")
print(modStack)

meanNDVI = mean(modStack, na.rm=TRUE)*0.0001 #mean of 5 periods plus scaling factor to make 0-1 NDVI value

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

surfaceModel=cover(reclassVeg, slpModelReclass) #0= veg, 1=debris , 2=steep bedrock

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
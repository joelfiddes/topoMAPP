#====================================================================
# SETUP
#====================================================================
#INFO
# extract timeseries of fSCA at coarse grid level

#DEPENDENCY
require(raster)
#require(MODIStsp) 

#SOURCE

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
sca_wd=args[2] 

cloudThreshold <- 0.2 # max cloud % to be considered "cloudfree"

# shpname = '/home/joel/sim/topomap_points/spatial/points.shp' 


#Set the input paths to raster and shape file
setwd(sca_wd)

MOD=stack(list.files(pattern="MOD*"))
MOD [MOD >100]<-NA
MOD_MEAN <- cellStats(MOD, 'mean') #fSCA for whole domain

MYD=stack(list.files(pattern="MYD*"))
MYD [MYD >100]<-NA
MYD_MEAN <- cellStats(MYD, 'mean') #fSCA for whole domain
#Npoints=dim(MOD)[1]

#compute cloudiness / NA
cloudinessMOD = cellStats(is.na(MOD),'sum') / ncell(MOD)
cloudfreeMOD= which(cloudinessMOD < cloudThreshold)
print(paste0("mean cloudiness TERRA MOD ",mean(cloudinessMOD)))
MOD_cf=MOD[[cloudfreeMOD]]

cloudinessMYD = cellStats(is.na(MYD),'sum') / ncell(MYD)
cloudfreeMYD= which(cloudinessMYD < cloudThreshold)
print(paste0("mean cloudiness AQUA MYD ",mean(cloudinessMYD)))
MYD_cf=MYD[[cloudfreeMYD]]

#plot(mod.date[cloudfreeMOD],MOD_MEAN[cloudfreeMOD])
#points(myd.date[cloudfreeMYD],MYD_MEAN[cloudfreeMYD], col='red')


MOD_cf=MOD[[cloudfreeMOD]]
MYD_cf=MYD[[cloudfreeMYD]]
if (mean(cloudinessMYD) < mean(cloudinessMOD)){ rstack <- MYD_cf}
if (mean(cloudinessMOD) < mean(cloudinessMYD)){ rstack <- MOD_cf}
# do cover here to merge obs to reduce NAs

#============================================================


# Combine timeseries
#MOD[MOD > 100]  <- NA
#MYD[MYD > 100]  <- NA

#DOesnt work for grids
#my.na <- is.na(MOD)
#MOD[my.na] <- MYD[my.na]

#construct dates
date = c()
for(i in 1: length( names(rstack)))
{
	year <- unlist(strsplit(names(rstack)[i], '_'))[4]
	doy <- unlist(strsplit(names(rstack)[i], '_'))[5]
	dd = strptime(paste(year, doy), format="%Y %j")
	date = c(date, as.character(dd))
	
}

setwd(wd)


#====================================================================
# convert ndsi to fsca
#====================================================================
fsca= (-0.01 + (1.45*rstack)) # https://modis-snow-ice.gsfc.nasa.gov/uploads/C6_MODIS_Snow_User_Guide.pdf
fsca [fsca >100]<-100

writeRaster(fsca, "fsca_stack.tif", overwrite=TRUE)
write.csv(date,"fsca_dates.csv", row.names=FALSE )




#====================================================================
# MODIS SA CODES
#====================================================================
# 0-100=NDSI snow 200=missing data
# 201=no decision
# 211=night
# 237=inland water 239=ocean
# 250=cloud
# 254=detector saturated 255=fill
#====================================================================
# MODIS SA CODES
#====================================================================

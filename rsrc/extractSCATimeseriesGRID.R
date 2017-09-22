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
shpname=args[3] 

wd='/home/joel/sim/topomap_points/'
sca_wd='/home/joel/data/MODIS_ARC/SCA/data/Snow_Cov_Daily_500m_v5/SC'
# shpname = '/home/joel/sim/topomap_points/spatial/points.shp' 


#Set the input paths to raster and shape file
setwd(sca_wd)

MOD=stack(list.files(pattern='MOD*'))
MOD [MOD >100]<-NA
MOD_MEAN <- cellStats(MOD, 'mean') #fSCA for whole domain

MYD=stack(list.files(pattern='MYD*'))
MYD [MYD >100]<-NA
MYD_MEAN <- cellStats(MYD, 'mean') #fSCA for whole domain
#Npoints=dim(MOD)[1]


# procedure to check for missing timestamps and fill with NA. Max date range defined by min and max of both MYD and MOD. 
#DONT NEED TO DO THIS: COMPLETE TIMESERIES NOT REQUIRED

#mod.ts = substr(list.files(pattern='MOD*'),13,20)
#mod.root = substr(list.files(pattern='MOD*'),1,12)[1]
#myd.ts = substr(list.files(pattern='MYD*'),13,20)
#myd.root = substr(list.files(pattern='MYD*'),1,12)[1]
#mod.date <- as.Date(mod.ts, format="%Y_%j") 
#myd.date <- as.Date(myd.ts, format="%Y_%j")

#mod.range <- seq(min(mod.date), max(mod.date), by = 1) 
#myd.range <- seq(min(mod.date), max(mod.date), by = 1) 

#all.min = min(min(mod.range), min(myd.range))
#all.max = max(c(max(mod.range), max(myd.range)))
#all.range <- seq(all.min, all.max, by = 1) 

#mod.miss = all.range[!all.range %in% mod.date]
#if (length(mod.miss) > 0)
#{
#	'missing dates'
#	date.format = format(as.Date(mod.miss, format="%Y-%m-%d"),format="%Y_%j")
#	inserts = paste0(mod.root,date.format)
#	vec = rep(NA,Npoints)
#	mat = replicate(length(mod.miss), vec)
#	df = as.data.frame(mat)
#	names(df) <- inserts
#	MOD = cbind(MOD,df)
#	MOD = MOD[,order(names(MOD))]


#}
# 
# myd.miss = all.range[!all.range %in% myd.date]
# if (length(myd.miss) > 0)
# 
# {
# 	'missing dates'
#	date.format = format(as.Date(myd.miss, format="%Y-%m-%d"),format="%Y_%j")
#	inserts = paste0(myd.root,date.format)
#	vec = rep(NA,Npoints)
#	mat = replicate(length(myd.miss), vec)
#	df = as.data.frame(mat)
#	names(df) <- inserts
#	MYD = cbind(MYD,df)
#	MYD = MYD[,order(names(MYD))]
# }

#check both are dataframes
#MOD = as.matrix(MOD)
#MYD = as.matrix(MYD)

#compute cloudiness / NA
cloudinessMOD = cellStats(is.na(MOD),'sum') / ncell(MOD)
cloudfreeMOD= which(cloudinessMOD < 0.2)
print(paste0("mean cloudiness TERRA MOD ",mean(cloudinessMOD)))
MOD_cf=MOD[[cloudfreeMOD]]

cloudinessMYD = cellStats(is.na(MYD),'sum') / ncell(MYD)
cloudfreeMYD= which(cloudinessMYD < 0.2)
print(paste0("mean cloudiness AQUA MYD ",mean(cloudinessMYD)))
MYD_cf=MYD[[cloudfreeMYD]]

plot(mod.date[cloudfreeMOD],MOD_MEAN[cloudfreeMOD])
points(myd.date[cloudfreeMYD],MYD_MEAN[cloudfreeMYD], col='red')


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
writeRaster(rstack, "fsca_stack.tif")
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

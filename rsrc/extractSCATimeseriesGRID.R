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

cloudThreshold <- 100 # max cloud % to be considered "cloudfree"

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

# Fill missing layers in each stack

# compute dates
mod.ts = substr(list.files(pattern='MOD*'),13,20)
mod.root = substr(list.files(pattern='MOD*'),1,12)[1]
myd.ts = substr(list.files(pattern='MYD*'),13,20)
myd.root = substr(list.files(pattern='MYD*'),1,12)[1]
mod.date <- as.Date(mod.ts, format="%Y_%j") 
myd.date <- as.Date(myd.ts, format="%Y_%j")

# hypothetical complete range of MOD or MYD
mod.range <- seq(min(mod.date), max(mod.date), by = 1) 
myd.range <- seq(min(mod.date), max(mod.date), by = 1) 

# hypothetical complete range of MOD AND MYD
all.min = min(min(mod.range), min(myd.range))
all.max = max(c(max(mod.range), max(myd.range)))
all.range <- seq(all.min, all.max, by = 1) 

# Index of missing layers
mod.miss = all.range[!all.range %in% mod.date]
myd.miss = all.range[!all.range %in% myd.date]
MOD.miss.ind <- which(all.range == mod.miss)
MYD.miss.ind <- which(all.range == myd.miss)

# index of no missing layers
mod.nomiss = all.range[all.range %in% mod.date]
myd.nomiss = all.range[all.range %in% myd.date]
MOD.nomiss.ind <- which(all.range %in% mod.nomiss)
MYD.nomiss.ind <- which(all.range == myd.nomiss)


# index of myd layers that correspond to missing mod layers
myd.missmod.ind <- which(myd.date %in% mod.miss)
mod.missmyd.ind <- which(mod.date %in% myd.miss)

# stack MOD and new MYD fill layers and index by MOD nomiss layer index and MOD miss layer index
MOD.layerfill <-subset(stack(MOD, MYD[[myd.missmod.ind]]),     order(c(MOD.nomiss.ind, MOD.miss.ind)))
MYD.layerfill <-subset(stack(MYD, MOD[[mod.missmyd.ind]]),     order(c(MYD.nomiss.ind, MYD.miss.ind)))

# MOD Na filled with MYD data if exists
MOD.fill = cover(MOD.layerfill, MYD.layerfill)

#count NA
MOD.na <- length(which(is.na(values(MOD))) )
MOD.fill.na <- length(which(is.na(values(MOD.fill))) )

print(paste0("orig NAs in MOD=",MOD.na,"New NAs in MOD=",MOD.fill.na,""))


#compute cloudiness / NA
cloudinessMOD = cellStats(is.na(MOD.fill),'sum') / ncell(MOD.fill)
cloudfreeMOD= which(cloudinessMOD < cloudThreshold)
print(paste0("mean cloudiness TERRA MOD ",mean(cloudinessMOD)))
MOD_cf=MOD.fill[[cloudfreeMOD]]

#cloudinessMYD = cellStats(is.na(MYD),'sum') / ncell(MYD)
#cloudfreeMYD= which(cloudinessMYD < cloudThreshold)
#print(paste0("mean cloudiness AQUA MYD ",mean(cloudinessMYD)))
#MYD_cf=MYD[[cloudfreeMYD]]

#plot(mod.date[cloudfreeMOD],MOD_MEAN[cloudfreeMOD])
#points(myd.date[cloudfreeMYD],MYD_MEAN[cloudfreeMYD], col='red')


#MOD_cf=MOD[[cloudfreeMOD]]
#MYD_cf=MYD[[cloudfreeMYD]]
#if (mean(cloudinessMYD) < mean(cloudinessMOD)){ rstack <- MYD_cf}
#if (mean(cloudinessMOD) < mean(cloudinessMYD)){ rstack <- MOD_cf}
## do cover here to merge obs to reduce NAs



#==================OUTPUTS==============================
rstack <- MOD_cf

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
fsca [fsca <0]<-0
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

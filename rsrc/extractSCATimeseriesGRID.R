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
#sptaialsubset=  raster("/home/joel/sim/ensembler_scale_sml/ensemble0/grid9/landform.tif")
#tempsubset =
#year = substr(list.files(pattern="MOD*"),13,16)
#doy = substr(list.files(pattern="MOD*"),18,20)

cloudThreshold <- 100 # max cloud % to be considered "cloudfree"

# shpname = '/home/joel/sim/topomap_points/spatial/points.shp' 


#Set the input paths to raster and shape file
setwd(sca_wd)


if( length(list.files(pattern="MOD*")) >0) {
	print(paste0(length(list.files(pattern="MOD*")), " MOD files found"))
	MOD=stack(list.files(pattern="MOD*"))
	print("MOD stack complete")
	MOD.names = names(MOD) # explicitly capture names to avoid loss
	#MOD [MOD >100]<-NA# filter non-ndsi values - this was hanging for some unknown reason, changed to simple loop

	for ( i in 1:dim(MOD)[3] ) {
		MOD[[i]][MOD[[i]] > 100]<-NA
		print(i)
	}

	print("MOD filter complete")
	names(MOD)<- MOD.names
	#MOD_MEAN <- cellStats(MOD, 'mean') #fSCA for whole domain
}


if( length(list.files(pattern="MYD*")) >0) {
	print(paste0(length(list.files(pattern="MYD*")), " MYD files found"))
	MYD=stack(list.files(pattern="MYD*"))
	print("MYD stack complete")
	MYD.names = names(MYD)
	#MYD [MYD >100]<-NA # filter non-ndsi values  - this was hanging for some unknown reason, changed to simple loop

	for ( i in 1:dim(MYD)[3] ) {
		MYD[[i]][MYD[[i]] > 100]<-NA
		print(i)
	}

	print("MYD filter complete")
	names(MYD)<- MYD.names
	#MYD_MEAN <- cellStats(MYD, 'mean') #fSCA for whole domain
}


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

# index of existing layers
mod.nomiss = all.range[all.range %in% mod.date]
myd.nomiss = all.range[all.range %in% myd.date]
MOD.nomiss.ind <- which(all.range %in% mod.nomiss)
MYD.nomiss.ind <- which(all.range == myd.nomiss)


# index of myd layers that correspond to missing mod layers
myd.missmod.ind <- which(myd.date %in% mod.miss)

if (length(myd.missmod.ind ) > 0){
# stack MOD and new MYD fill layers and index by MOD nomiss layer index and MOD miss layer index
MOD.layerfill <-subset(stack(MOD, MYD[[myd.missmod.ind]]),     order(c(MOD.nomiss.ind, MOD.miss.ind)))
print("MOD date gaps filled with MYD")
	}
if (length(myd.missmod.ind ) == 0){
	MOD.layerfill <- MOD
print("No MOD date gaps found")
	}

# index of mod layers that correspond to missing myd layers
mod.missmyd.ind <- which(mod.date %in% myd.miss)

if (length(mod.missmyd.ind ) > 0){
# stack MOD and new MYD fill layers and index by MOD nomiss layer index and MOD miss layer index
	MYD.layerfill <-subset(stack(MYD, MOD[[mod.missmyd.ind]]),     order(c(MYD.nomiss.ind, MYD.miss.ind)))
	print("MYD date gaps filled with MOD")
	}

if (length(mod.missmyd.ind ) == 0){
	MYD.layerfill <- MYD
	print("No MYD date gaps found")
	}

# MOD Na cells filled with MYD data if exists :  Replace ‘NA’ values in the first Raster object (‘x’) with the values of the second (‘y’), and so forth for  additional Rasters. 

#implement as loop to avoid large datset problems that existed
rstack = stack()
for (i in 1:nlayers(MOD.layerfill)){
	rstack  = stack(rstack,  cover(MOD.layerfill[[i]], MYD.layerfill[[i]]))
	print(paste0("filled layer: " ,i)
}
MOD.fill <- rstack
names(MOD.fill) <- names(MOD.layerfill)


#count NA
MOD.na <- length(which(is.na(values(MOD.layerfill))) )
MOD.fill.na <- length(which(is.na(values(MOD.fill))) )

oldNa <- (MOD.na/(ncell(MOD.layerfill)* nlayers(MOD.layerfill)))*100

newNa <- (MOD.fill.na/(ncell(MOD.layerfill)* nlayers(MOD.layerfill)))*100



print(paste0("orig NAs in MOD=",round(oldNa,2),"% New NAs in filled MOD=",round(newNa,2),"%"))

#}else {MOD.fill <- MOD}

#compute cloudiness / NA
# cloudinessMOD = cellStats(is.na(MOD.fill),'sum') / ncell(MOD.fill)
# cloudfreeMOD= which(cloudinessMOD < cloudThreshold)
# print(paste0("mean cloudiness TERRA MOD ",round(mean(cloudinessMOD),2)))
# MOD_cf=MOD.fill[[cloudfreeMOD]]



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

#====================================================================
# SETUP
#====================================================================
#INFO
#use MAGST or MASD or SWE

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

# wd='/home/joel/sim/topomap_points/'
# sca_wd='/home/joel/data/MODIS_ARC/SCA/data/Snow_Cov_Daily_500m_v5/SC'
# shpname = '/home/joel/sim/topomap_points/spatial/points.shp' 


#Set the input paths to raster and shape file
setwd(sca_wd)
shp = shapefile(shpname)
rstack=stack(list.files(pattern='MOD*'))
MOD = extract(rstack, shp)
rstack=stack(list.files(pattern='MYD*'))
MYD = extract(rstack, shp)

Npoints=dim(MOD)[1]


# procedure to check for missing timestamps and fill with NA. Max date range defined by min and max of both MYD and MOD.

mod.ts = substr(list.files(pattern='MOD*'),13,20)
mod.root = substr(list.files(pattern='MOD*'),1,12)[1]
myd.ts = substr(list.files(pattern='MYD*'),13,20)
myd.root = substr(list.files(pattern='MYD*'),1,12)[1]
mod.date <- as.Date(mod.ts, format="%Y_%j") 
myd.date <- as.Date(myd.ts, format="%Y_%j")

mod.range <- seq(min(mod.date), max(mod.date), by = 1) 
myd.range <- seq(min(mod.date), max(mod.date), by = 1) 

all.min = min(min(mod.range), min(myd.range))
all.max = max(c(max(mod.range), max(myd.range)))
all.range <- seq(all.min, all.max, by = 1) 

mod.miss = all.range[!all.range %in% mod.date]
if (length(mod.miss) > 0)
{
	'missing dates'
	date.format = format(as.Date(mod.miss, format="%Y-%m-%d"),format="%Y_%j")
	inserts = paste0(mod.root,date.format)
	vec = rep(NA,Npoints)
	mat = replicate(length(mod.miss), vec)
	df = as.data.frame(mat)
	names(df) <- inserts
	MOD = cbind(MOD,df)
	MOD = MOD[,order(names(MOD))]


}
 
 myd.miss = all.range[!all.range %in% myd.date]
 if (length(myd.miss) > 0)
 
 {
 	'missing dates'
	date.format = format(as.Date(myd.miss, format="%Y-%m-%d"),format="%Y_%j")
	inserts = paste0(myd.root,date.format)
	vec = rep(NA,Npoints)
	mat = replicate(length(myd.miss), vec)
	df = as.data.frame(mat)
	names(df) <- inserts
	MYD = cbind(MYD,df)
	MYD = MYD[,order(names(MYD))]
 }

#check both are dataframes
MOD = as.matrix(MOD)
MYD = as.matrix(MYD)


#============================================================


# Combine timeseries
MOD[MOD > 100]  <- NA
MYD[MYD > 100]  <- NA

my.na <- is.na(MOD)
MOD[my.na] <- MYD[my.na]

# convert ndsi to fsca
fsca.df= (-0.01 + (1.45*MOD)) # https://modis-snow-ice.gsfc.nasa.gov/uploads/C6_MODIS_Snow_User_Guide.pdf
fsca.df [fsca.df >100]<-100
fsca.df [fsca.df <0]<-0


#construct dates
date = c()

x = names(MOD[2,])

for(i in 1: length( x))
{
	year <- unlist(strsplit(x[i], '_'))[4]
	doy <- unlist(strsplit(x[i], '_'))[5]
	dd = strptime(paste(year, doy), format="%Y %j")
	date = c(date, as.character(dd))
	
}



write.csv(date,paste0(wd,"/fsca_dates.csv"), row.names=FALSE )

#construct dataframes
df=c()
for (i in 1:Npoints)
{
	fsca = as.vector(fsca.df[i,])
	df = cbind(df, fsca)


}
df = data.frame(df)

names(df) <- paste0("p", 1:Npoints)
	write.csv(df,paste0(wd,"/fsca_obs.csv"), row.names=FALSE )
	
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

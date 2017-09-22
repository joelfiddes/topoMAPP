#====================================================================
# SETUP
#====================================================================
#INFO
#use MAGST or MASD or SWE

#DEPENDENCY
require(raster)
require(rgdal)
#SOURCE

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
valDat=args[1]
modDat=args[2]
magstCol=as.numeric(args[3])
lonCol=as.numeric(args[4])
latCol=as.numeric(args[5])
gridPath=args[6] #/home/joel/sim/topomap_test//grid1

#====================================================================
# PARAMETERS FIXED
#====================================================================

#**********************  SCRIPT BEGIN *******************************
setwd(gridPath)
dat= read.table(valDat, sep=',', header=TRUE)


# FUNCTION
proj='+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'
lon=dat[,lonCol]
lat=dat[,latCol]
loc<-data.frame(lon, lat)
shp<-SpatialPointsDataFrame(loc,as.data.frame(dat), proj4string= CRS(proj))
	
rst=raster('landform.tif')
cp <- as(extent(rst), "SpatialPolygons")

valpoints=extract(rst,shp)
valIndex=which(is.na(valpoints)==FALSE)
magstVal= dat$Temp[valIndex]
modfile=read.table(modDat)
magstMod=modfile[valpoints[valIndex],]

if (length(magstVal)==0) {
	print("No val points in this grid")
} else {
	print(magstMod)
	print(magstVal)
	plot(magstMod, magstVal, xlab='modelled', ylab='measured')
}
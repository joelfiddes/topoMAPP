#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1] #'/home/joel/sim/topomap_test/grid1' #

#====================================================================
# PARAMETERS FIXED
#====================================================================
points=paste0(wd,'/listpoints.txt')
#**********************  SCRIPT BEGIN *******************************
setwd(wd)


# FUNCTION
makePointShapeGeneriRc=function(lon,lat,data,proj='+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'){
library(raster)
library(rgdal)
loc<-data.frame(lon, lat)
spoints<-SpatialPointsDataFrame(loc,as.data.frame(data), proj4string= CRS(proj))
return(spoints)
}

#CODE
dat=read.table(points, sep=',', header=T)
shp=makePointShapeGeneriRc(lon=dat$lon,lat=dat$lat,data=dat,proj='+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')


#get surface type of each point , 0=vegetation, 1=debris, 2=steep bedrock
lc=raster('predictors/surface.tif')
zoneStats=extract(lc,shp)
zone = 1:dim(shp)[1]
value = zoneStats
df = data.frame(zone, value)
write.table(df,'landcoverZones.txt',sep=',', row.names=F)
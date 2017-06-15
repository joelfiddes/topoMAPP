#====================================================================
# SETUP
#====================================================================
#INFO
# reads comma separated files with header

#DEPENDENCY
require(raster)
#require(MODIStsp) 

#SOURCE

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
infile=args[2] 
loncol=as.numeric( args[3] )
latcol=as.numeric( args[4] )


# FUNCTION
makePointShapeGeneriRc=function(lon,lat,data,proj='+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'){
library(raster)
library(rgdal)
loc<-data.frame(lon, lat)
spoints<-SpatialPointsDataFrame(loc,as.data.frame(data), proj4string= CRS(proj))
return(spoints)
}

#CODE
setwd(wd)
dat=read.table(infile, sep=',', header=T)
shp=makePointShapeGeneriRc(lon=dat[,loncol],lat=dat[,latcol],data=dat,proj='+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')


#WRITE
shapefile(x=shp,filename='spatial/points.shp',overwrite=TRUE)

#nb: do not use '~/'
#nb: overwrite does not work, if file exists function fails.




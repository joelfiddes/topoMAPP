#====================================================================
# SETUP
#====================================================================
#INFO
#account required https://urs.earthdata.nasa.gov/profile

#DEPENDENCY
require(raster)

#SOURCE

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd= args[1] #"/home/joel/sim/testDem" #args[1]
demDir= args[2] #"/home/joel/data/DEM/srtm" 
rst = args[3] #"/home/joel/src/topoMAPP/dat/eraigrid75.tif"
shp= args[4] #"/home/joel/data/GCOS/wfj_poly.shp"

#====================================================================
# PARAMETERS FIXED
#====================================================================
#DEM Data dir
#parse credentials file to get user/pwd: https://urs.earthdata.nasa.gov/profile
#to create ~/.netrc credentials file run lpdaacLogin() (install.package('MODIS')
SERVICE=unlist(strsplit(readLines("~/.netrc")[[1]]," "))[2]
print(paste0('using credentials for: ', SERVICE))
USER=unlist(strsplit(readLines("~/.netrc")[[2]]," "))[2]
PWD=unlist(strsplit(readLines("~/.netrc")[[3]]," "))[2]

#====================================================================
# DEM retrieval based on set of points:
#====================================================================
dir.create(paste0(wd,'/predictors'), showWarnings=FALSE)
dir.create(paste0(wd,'/spatial'), showWarnings=FALSE)
setwd(demDir)

aoi=shapefile(shp)
rst=raster(rst)

# single / multipoint shape AOI
if ( class(aoi)=="SpatialPointsDataFrame"){

	# cell corresponding to point
	ncell = cellFromXY(rst, aoi)

	# extract that cell
	r2 <- rasterFromCells(rst, ncell, values=TRUE)

	# extent of era gridcells covered by AOI
	eraExtent=extent(r2)
	}

# polygon AOI
if(class(aoi)=="SpatialPolygons"  | class(aoi)=="SpatialPolygonsDataFrame"){

	# crop raster with polygon and snap out
	eraExtent=extent(crop(rst,aoi, snap='out'))

	}

# extent in whole degrees for dem download to completely cover eragrid cell
demExtent = floor(eraExtent)

# get range of ll corners for dem download -1 term prevents neighbouring grid being downloaded
lon = c(demExtent@xmin: (demExtent@xmax -1) )
lat = c(demExtent@ymin: (demExtent@ymax -1) )

# if dimensions are different then replication will occur - watch this
if ( length(lon) == length(lat) ){
df= expand.grid(data.frame(lon,lat))
} else {



latmat = matrix(rep(lat, length(lon)),ncol=length(lon),nrow=length(lat))

lonmat = matrix(rep(lon, length(lat)),ncol=length(lon),nrow=length(lat),byrow=TRUE)
lon=as.vector(latmat)
lat = as.vector(lonmat)
df= data.frame(lon,lat)
}

	ngrids=length(df[,1])
	print (paste0("Retrieving ",ngrids, " SRTM30 grids (1x1 deg)"))
	#clean up
	system("rm SRTMDAT*")
	system("rm *.hgt")

	for (i in 1:(dim(df)[1])){
		if (sign(df$lat[i])==-1){LATVAL<-"S"}
		if (sign(df$lat[i])==1){LATVAL<-"N"}
		if (sign(df$lon[i])==-1){LONVAL<-"W"}
		if (sign(df$lon[i])==1){LONVAL<-"E"}
		lon_pretty=formatC(abs(df$lon[i]),width=3,flag="0")
		#get tile
		filetoget=paste0(LATVAL,abs(df$lat[i]),LONVAL,lon_pretty,".SRTMGL1.hgt.zip")
		filetogetUNZIP=paste0(LATVAL,abs(df$lat[i]),LONVAL,lon_pretty,".hgt")

	if (file.exists(filetoget)){ #dont download again
	   print(paste0(filetoget, " exists"))
	   	system(paste0("unzip ", filetoget))
		system(paste0("gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 ", filetogetUNZIP, " SRTMDAT",i,".tif"))
		} else {
		 
			system(paste0("wget --user ", USER ,  " --password " ,PWD, " http://e4ftl01.cr.usgs.gov//MODV6_Dal_D/SRTM/SRTMGL1.003/2000.02.11/",filetoget))
			# extract
			system(paste0("unzip ", filetoget))
			system(paste0("gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 ", filetogetUNZIP, " SRTMDAT",i,".tif"))
		}
	}

#====================================================================
# MERGE RASTER
#====================================================================
demfiles=list.files(pattern="SRTMDAT*")
if(length(demfiles)>1){
rasters1 <- list.files(pattern="SRTMDAT*",full.names=TRUE, recursive=FALSE)
rast.list <- list()
  for(i in 1:length(rasters1)) { rast.list[i] <- raster(rasters1[i]) }

# And then use do.call on the list of raster objects
rast.list$fun <- mean
rast.mosaic <- do.call(mosaic,rast.list)
dem<-rast.mosaic
}else{
	dem <- raster(demfiles)
}
#setwd(wd)

# crop merged raster to eraExtent
ele <- crop(dem, eraExtent)

#outputs
writeRaster(ele, paste0(wd, '/predictors/ele.tif'), overwrite=TRUE)

eraExtent2=crop(rst,aoi, snap='out')
writeRaster(eraExtent2, paste0(wd, '/spatial/eraExtent.tif'), overwrite=TRUE)

# plot of setup
pdf(paste0(wd, '/spatial/extentMap.pdf'))

if(class(aoi)=="SpatialPolygons"  | class(aoi)=="SpatialPolygonsDataFrame"){
	plot(dem, main="AOI=red, ERA-grid=green")
	plot(aoi,add=T, border='red', lwd=3)
	rst2 = crop(rst,aoi, snap='out')
	r3 <- rasterToPolygons(rst2, dissolve=TRUE)
	}

if ( class(aoi)=="SpatialPointsDataFrame"){
	plot(dem, main="Points=red, ERA-grid=green")
	plot(aoi,add=T, col='red', lwd=3)
	r3 <- rasterToPolygons(r2, dissolve=TRUE)
	}

plot(r3,add=T, border='green', lwd=3)
dev.off()
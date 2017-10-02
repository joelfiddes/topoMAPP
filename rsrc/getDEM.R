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
wd=args[1]
demDir=args[2]
#runtype=args[2]
#box=as.numeric(unlist(strsplit( args[3],",")))
bbox=c(as.numeric(args[3]),as.numeric(args[4]),as.numeric(args[5]),as.numeric(args[6])) # w,s,e,n
#grid=args[3]
#points input
#lon=c(85.52 ,85.68,84.2)
#lat=c(28.1 ,28.3, 27.8)
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



#bbox=(e,s,w,n)
#bbox=c(85.1, 27.7, 85.8, 27.8)

#compute_svf<-FALSE

#**********************  SCRIPT BEGIN *******************************
dir.create(paste0(wd,'/predictors'), showWarnings=FALSE)
setwd(demDir)


#====================================================================
# DEM retrieval based on set of points:
#====================================================================
# if (runtype == "points"){
# 	setwd(demDir)
# 	df=data.frame(lon,lat)

# 	#find unique llcorner
# 	df2=unique(floor(df))

# 	#clean up
# 	system("rm SRTMDAT*")
# 	system("rm *.hgt")

# 	for (i in 1:(dim(df2)[1])){
# 		if (sign(df2$lat[i])==-1){LATVAL<-"S"}
# 		if (sign(df2$lat[i])==1){LATVAL<-"N"}
# 		if (sign(df2$lon[i])==-1){LONVAL<-"W"}
# 		if (sign(df2$lon[i])==1){LONVAL<-"E"}
# 		lon_pretty=formatC(df2$lon[i],width=3,flag="0")
# 		#get tile
# 		filetoget=paste0(LATVAL,df2$lat[i],LONVAL,lon_pretty,".SRTMGL1.hgt.zip")
# 		filetogetUNZIP=paste0(LATVAL,df2$lat[i],LONVAL,lon_pretty,".hgt")

# 	if (file.exists(filetoget)){ #dont download again
# 	   print(paste0(filetoget, " exists"))
# 	   	system(paste0("unzip ", filetoget))
# 		system(paste0("gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 ", filetogetUNZIP, " SRTMDAT",i,".tif"))
# 		} else {
		 
# 			system(paste0("wget --user ", USER ,  " --password " ,PWD, " http://e4ftl01.cr.usgs.gov//MODV6_Dal_D/SRTM/SRTMGL1.003/2000.02.11/",filetoget))
# 			# extract
# 			system(paste0("unzip ", filetoget))
# 			system(paste0("gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 ", filetogetUNZIP, " SRTMDAT",i,".tif"))
# 		}
# 	}
# }
#


#====================================================================
# DEM retrieval based on bbox
#====================================================================
#if (runtype == "bbox"){
	setwd(demDir)
	floorbox=floor(bbox)

	#reduce by 1 longlat seq to prevent neighbouring tile being downloaded - coords are ll corner. bbox with coord = 8 46  9 47 means just give me a sing 1x1 deg tile with coords in ll corner of 8,46. Without the subtraction of 1 we would get 4 1*1 deg tiles ie 8,46 + 8,47 + 9,46 + 9,47
	floorbox[3]  <- floorbox[3] -1 
	floorbox[4]  <- floorbox[4] -1 

	lonseq=seq(floorbox[1],floorbox[3],1)
	latseq=seq(floorbox[2],floorbox[4],1)
	gridstoget=expand.grid(lonseq,latseq)
	names(gridstoget)<-c("lon", "lat")
	df2<-gridstoget

	ngrids=length(df2[,1])
	print (paste0("Retrieving ",ngrids, " SRTM30 grids (1x1 deg)"))
	#cleanup
	system("rm SRTMDAT*")
	system("rm *.hgt")

	for (i in 1:(dim(df2)[1])){
		if (sign(df2$lat[i])==-1){LATVAL<-"S"}
		if (sign(df2$lat[i])==1){LATVAL<-"N"}
		if (sign(df2$lon[i])==-1){LONVAL<-"W"}
		if (sign(df2$lon[i])==1){LONVAL<-"E"}
		lon_pretty=formatC(abs(df2$lon[i]),width=3,flag="0")
		#get tile
		filetoget=paste0(LATVAL,abs(df2$lat[i]),LONVAL,lon_pretty,".SRTMGL1.hgt.zip")
		filetogetUNZIP=paste0(LATVAL,abs(df2$lat[i]),LONVAL,lon_pretty,".hgt")

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
#}
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
setwd(wd)
writeRaster(dem, 'predictors/dem.tif', overwrite=TRUE)

#outline = rasterToPolygons(dem)
#shapefile(outline,"extentRequest.shp")
#====================================================================
# CLIP TO NEAREST ERA EXTENT
#====================================================================
# #parameters
# ele=dem
# tol=0 #must be greater than 0.5*box resolution to get correct extent in degrees
# xtent=extent(ele)
# n=xtent@ymax+tol
# s=xtent@ymin-tol
# e=xtent@xmax+tol
# w=xtent@xmin-tol
# ar= paste(n,w,s,e,sep='/')# region of interest N/W/S/E this corresponds to box centres
# t='00/12'#00/12 gives 3hr data for sfc retrieval ; 00/06/12/18 gives 6hr data for pl retrieval (3hr not possible) ; 00/12 for accumulated
# stp='3/6/9/12'#3/6/9/12 gives 3hr data for sfc ; 0 gives 6hr data for pl retrieval (3hr not possible)
# lt='sfc'# sfc=surface or pl=pressure level
# typ='fc'#an=analysis or fc=forecast, depends on parameter - check on ERA gui.
# par= 168# parameter code - check on ERA gui.
# tar='eraExtent.nc'
# grd=paste0(grid,'/',grid)
# dd="20121230/to/20121231"

# #request
# getERA(dd=dd, t=t, grd=grd, stp=stp, lt=lt,typ=typ,par=par,ar=ar,tar=tar,plev=NULL,workd=wd)
# eraExtent=raster('eraExtent.nc')

# # crop domain to era grids completely covered by DEM - this will lose margin of dem
# # accuracy of these two extents is around half DEm pixel = 15m ie can be 15m difference in boudaries

# newExtent=crop(eraExtent,ele,snap='in')
# newDEM=crop(ele,newExtent)
# writeRaster(newExtent, 'eraExtent.tif', overwrite=TRUE)
# dem<-newDEM

# #plot of simulation domain
# pdf('extentMap.pdf')
# plot(extent(eraExtent),col='green', lwd=2, main='New extent of ERA-grids overlaid input DEM.' , sub='New DEM outline (blue). Original ERA request (green)')
# plot(ele,add=TRUE, lwd=2)
# plot(rasterToPolygons(newExtent),add=TRUE, lwd=2)
# plot(extent(newDEM),add=TRUE, col='blue', lwd=2)
# dev.off()






#====================================================================
# EXTRACT SVF
#====================================================================
# #https://cran.r-project.org/web/packages/horizon/horizon.pdf
# #http://onlinelibrary.wiley.com/doi/10.1002/joc.3523/pdf
# if (compute_svf == TRUE){
# r <- dem
# s <- svf(r, nAngles=4, maxDist=500, ll=TRUE)

# setwd(paste0(wd,'/predictors'))
# writeRaster(round(s,2), "svf.tif", overwrite=TRUE) #write and reduce precision

# }
# #perhaps need to do this on indiv tiles for memory issues?

# #====================================================================
# # EXTRACT SLP/ASP
# #================================================================= ==
# slp=terrain(dem, opt="slope", unit="degrees", neighbors=8)
# asp=terrain(dem, opt="aspect", unit="degrees", neighbors=8)

# #====================================================================
# # WRITE OUTPUTS
# #====================================================================
# setwd(paste0(wd,'/predictors'))
# writeRaster(round(slp,0), "slp.tif", overwrite=TRUE) #write and reduce precision
# writeRaster(round(asp,0), "asp.tif", overwrite=TRUE) #write and reduce precision
# writeRaster(dem, "ele.tif", overwrite=TRUE)

# #====================================================================
# # CLEANUP
# #====================================================================
# rm(list = ls())

#====================================================================
# OUTPUT
#====================================================================

# dem.tif in longlat
# asp.tif in degrees
# slp.tif in degrees
# svf.tif

#write these to predictors dir


#====================================================================
# OLDSTUFF
#====================================================================
# elevation: https://pypi.python.org/pypi/elevation #perhaps not anymore?
#erathdata login: https://urs.earthdata.nasa.gov/profile
#gdal_translate

#pypi/elevation
# eio clip -o yala.tif --bounds 12.35 41.8 12.65 42
# eio clip -o test1.tif --bounds 12.35 31.8 12.65 32.1
# eio clip -o langtang.tif --bounds 85.52 28.1 85.68 28.3
# 85.52 28.1 85.68 28.2


#this works

# wget --user USER --password PWD http://e4ftl01.cr.usgs.gov//MODV6_Dal_D/SRTM/SRTMGL1.003/2000.02.11/N28E085.SRTMGL1.hgt.zip
# unzip  N28E085.SRTMGL1.hgt.zip
# gdal_translate -q -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 N28E085.hgt SRTMDAT.tif

#naming convention  http://e4ftl01.cr.usgs.gov//MODV6_Dal_D/SRTM/SRTMGL1.003/2000.02.11/
#name of dem file is llcorner 1deg tiles
# to find tile need to round down long/let to nearest degree




#points by google-api
#wget https://maps.googleapis.com/maps/api/elevation/json?locations=43.7391536,8.9847034&key=AIzaSyCTCRL-sszoCWqzNHcKz4FrAwJLvh7A3x8

#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY

#SOURCE

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
gridpath=args[1]
Nclust=args[2]
file1=args[3]
targV=args[4]

#====================================================================
# PARAMETERS FIXED
#====================================================================

#====================================================================
# TOPOSUB POSTPROCESSOR 2		
#====================================================================
setwd(gridpath)
outfile=paste('/meanX_',targV,'.txt',sep='')
file.create(outfile)

for ( i in 1:Nclust){
gsimindex=formatC(i, width=5,flag='0')
simindex=paste0('S',formatC(i, width=5,flag='0'))


#read in lsm output
sim_dat=read.table(paste(simindex,file1,sep=''), sep=',', header=T)
#cut timeseries
sim_dat_cut=timeSeriesCut(esPath=simindex,col=targV, sim_dat=sim_dat, beg=beg, end=end)	
#mean annual values
timeSeries2(spath=gridpath,col=targV, sim_dat_cut=sim_dat_cut,FUN=mean)
}
#write success file
outfile=paste(gridpath,'/POSTPROCESS_2_SUCCESS.txt',sep='')
file.create(outfile)
##make crisp maps
landform<-raster("landform.tif")

if(crisp==TRUE){
crispSpatial2(col=targV,Nclust=Nclust,esPath=gridpath, landform=landform)
}
#make fuzzy maps
if(fuzzy==TRUE){
	mask=raster(paste('/mask',predFormat,sep=''))
	#fuzSpatial(col=targV, esPath=gridpath, format=predFormat, Nclust=Nclust,mask=mask)
fuzSpatial_subsum(col=targV, esPath=gridpath, format=predFormat, Nclust=Nclust, mask=mask)
	}

if(VALIDATE==TRUE){
dat <- read.table(paste('/meanX_',targV,'.txt',sep=''), sep=',',header=F)
dat<-dat$V1
fuzRes=calcFuzPoint(dat=dat,fuzMemMat=fuzMemMat)

write.table(fuzRes, '/fuzRes.txt', sep=',', row.names=FALSE)
}

##==============================================================================
## MERGE RASTERS
##==============================================================================
#rs=list.files(epath, pattern='X100.000000_100.tif', recursive=T)
#rst=paste(epath,rs,sep='')
#rmerge=round(merge(raster(rst[1]),raster(rst[2]),raster(rst[3]),raster(rst[4]),raster(rst[5]),raster(rst[6]),raster(rst[7]),raster(rst[8]),raster(rst[9]),raster(rst[10]),raster(rst[11]),raster(rst[12]),raster(rst[13]),raster(rst[14]),raster(rst[15]),raster(rst[16]),raster(rst[17]),raster(rst[18])),1)


#writeRaster(rmerge, paste(epath,'rmerge3.tif',sep=''), NAflag=-9999,overwrite=T,options="COMPRESS=LZW")
#t4=Sys.time()-t1

#png('/home/joel/Documents/posters_presentations/kolloqium/alps.png',width=1200,height=900)
#plot(rmerge, col=matlab.like(100),maxpixels=3000000)
#dev.off()



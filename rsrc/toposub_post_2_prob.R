#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)
#SOURCE
source("./rsrc/toposub_src.R")
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args <- 	commandArgs(trailingOnly=TRUE)
gridpath <- args[1]
Nclust <-	args[2]
file1 <- 	args[3]
targV <- 	args[4]
beg <- 		args[5]
end <- 		args[6]
lf <-       args[7]
#====================================================================
# PARAMETERS FIXED
#====================================================================
# Timeformats: This needs to be aligned with main time input
#beg <- "01/07/2010 00:00:00"
#end <- "01/07/2011 00:00:00"
	crisp <- TRUE #other options as separate functions]
	fuzzy <- FALSE
	VALIDATE <- FALSE

#========================================================================
#		FORMAT DATE
#========================================================================
d=strptime(beg, format="%Y-%m-%d", tz=" ")
geotopStart=format(d, "%d/%m/%Y %H:%M")

d=strptime(end, format="%Y-%m-%d", tz=" ")
geotopEnd=format(d, "%d/%m/%Y %H:%M")
#====================================================================
# TOPOSUB POSTPROCESSOR 2		
#====================================================================
setwd(gridpath)
ensemble <- list.dirs(full.names=F, recursive=F)

for (j in ensemble){

ensPath = paste0(gridpath,"/",j,"/grid1/")
print(ensPath)
#setwd(paste0(gridpath,"/",j,"/grid1/"))

outfile <- paste0(ensPath,'/meanX_',targV,'.txt')
file.create(outfile)

for ( i in 1:Nclust){
	#gsimindex=formatC(i, width=5,flag='0')
	simindex <- paste0(ensPath, "/S",formatC(i, width=5,flag='0'))

	#read in lsm output
	sim_dat <- read.table(paste(simindex,'/out/',file1,sep=''), sep=',', header=T)

	#cut timeseries
	sim_dat_cut <- timeSeriesCut( sim_dat=sim_dat, beg=geotopStart, end=geotopEnd)	

	#mean annual values
	#timeSeries2(spath=gridpath,colP=targV, sim_dat_cut=sim_dat_cut,FUN=mean)

	#compute mean value of target variable for sample
	meanX<-	tapply(sim_dat_cut[,targV],sim_dat_cut$IDpoint, FUN=mean)

	#append to master file
	write(meanX, paste(ensPath, '/meanX_', targV,'.txt', sep=''), sep=',',append=T)
	}

if(crisp==TRUE){
	##make crisp maps
	landform<-raster(lf)	
	rst = crispSpatial2(col=targV,Nclust=Nclust, landform=landform, esPath=ensPath)
	#writeRaster(rst, paste0(gridpath,"/",targV,j ))
	}

# ============== NEW FUNCTIONS NEEDED ======================
#make fuzzy maps
if(fuzzy==TRUE){
	mask=raster(paste('/mask',predFormat,sep=''))
	#fuzSpatial(col=targV, esPath=gridpath, format=predFormat, Nclust=Nclust,mask=mask)
	fuzSpatial_subsum(col=targV, esPath=gridpath, format=predFormat, Nclust=Nclust, mask=mask)
	}

if(VALIDATE==TRUE){
	dat <- read.table(paste('/meanX_',targV,'.txt',sep=''), sep=',',header=F)
	dat<-dat$V1
	fuzRes <- calcFuzPoint(dat=dat,fuzMemMat=fuzMemMat)
	write.table(fuzRes, '/fuzRes.txt', sep=',', row.names=FALSE)
	}

}


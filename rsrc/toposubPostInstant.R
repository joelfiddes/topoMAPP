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
#====================================================================
# PARAMETERS FIXED
#====================================================================
# Timeformats: This needs to be aligned with main time input
#beg <- "01/07/2010 00:00:00"
#end <- "01/07/2011 00:00:00"
	crisp <- TRUE #other options as separate functions]
	fuzzy <- FALSE
	VALIDATE <- FALSE
#====================================================================
# TOPOSUB POSTPROCESSOR 2		
#====================================================================
setwd(gridpath)
outfile <- paste('latest_',targV,'.txt',sep='')
file.create(outfile)

for ( i in 1:Nclust){
	#gsimindex=formatC(i, width=5,flag='0')
	simindex <- paste0('S',formatC(i, width=5,flag='0'))

	#read in lsm output
	sim_dat <- read.table(paste(simindex,'/out/',file1,sep=''), sep=',', header=T)

	# Get last data point
	latestDat <- sim_dat[length(sim_dat[,targV]),targV]
	

	#append to master file
	write(latestDat, paste(gridpath, '/latest_', targV,'.txt', sep=''), sep=',',append=T)
	}

if(crisp==TRUE){
	##make crisp maps
	landform<-raster("landform.tif")	
	crispSpatialInstant(col=targV,Nclust=Nclust,esPath=gridpath, landform=landform)
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




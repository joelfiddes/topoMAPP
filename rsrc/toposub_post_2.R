#====================================================================
# SETUP
#====================================================================
#INFO
# Genrates mean annual maps
# example: joel@myserver:~/src/topoMAPP$ Rscript rsrc/toposub_post_2.R /home/joel/sim/gperm/grid1/ 200 ground.txt X9999.000000 01.09.2006 01.09.2017
# generates mean annual temp at 10m

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
beg <- 		args[5] #"%Y-%m-%d"
end <- 		args[6] #"%Y-%m-%d"
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
outfile <- paste('meanX_',targV,'.txt',sep='')
file.create(outfile)

for ( i in 1:Nclust){
	#gsimindex=formatC(i, width=5,flag='0')
	simindex <- paste0('S',formatC(i, width=5,flag='0'))

	#read in lsm output
	sim_dat <- read.table(paste(simindex,'/out/',file1,sep=''), sep=',', header=T)

	#cut timeseries
	sim_dat_cut <- timeSeriesCut( sim_dat=sim_dat, beg=geotopStart, end=geotopEnd)	

	#mean annual values
	#timeSeries2(spath=gridpath,colP=targV, sim_dat_cut=sim_dat_cut,FUN=mean)

	#compute mean value of target variable for sample
	meanX<-	tapply(sim_dat_cut[,targV],sim_dat_cut$IDpoint, FUN=mean)

	#append to master file
	write(meanX, paste(gridpath, '/meanX_', targV,'.txt', sep=''), sep=',',append=T)
	}

if(crisp==TRUE){
	##make crisp maps
	landform<-raster("landform.tif")	
	crispSpatial2(col=targV,Nclust=Nclust,esPath=gridpath, landform=landform)
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




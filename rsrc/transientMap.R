#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)
#SOURCE
source("./rsrc/toposub_src.R")

# run as Rscript rsrc/transientMap.R /home/joel/sim/yala_interim_long/grid1/ gst 1990-01-01 1990-12-31

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args <- 	commandArgs(trailingOnly=TRUE)
gridpath <- args[1]
tv <- 	args[2]
beg <- 		args[3]
end <- 		args[4]
#====================================================================
# PARAMETERS FIXED
#====================================================================
# Timeformats: This needs to be aligned with main time input
#beg <- "01/07/2010 00:00:00"
#end <- "01/07/2011 00:00:00"
	crisp <- TRUE #other options as separate functions]
	fuzzy <- FALSE
	VALIDATE <- FALSE

if (tv=='gst'){file1="ground.txt" ;targV="X100.000000" }
if (tv=='swe'){file1="surface.txt" ;targV="snow_water_equivalent.mm." }
Nclust = length(list.files(path = gridpath, pattern="^S"))

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
	col=targV
	Nclust=Nclust
	esPath=gridpath
	land=landform
	meanX <- read.table(paste(esPath, '/meanX_', col,'.txt', sep=''), sep=',')
	meanX = as.vector(meanX)
		l = length(meanX$V1)
		seq1 = seq(1,l,1)
		seq1 = as.vector(seq1)
		meanXdf = data.frame(seq1,meanX)
		rst = subs(land, meanXdf,by=1, which=2)
		rst=round(rst,2)
		writeRaster(rst, paste(esPath,'/crisp_',col,'_',l,"_",beg,"_",end,'.tif', sep=''),overwrite=T)
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




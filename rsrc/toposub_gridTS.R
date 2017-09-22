# This tool extracts a mean timeseries from toposub results
# here it needs to return SCA

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
# TOPOSUB POSTPROCESSOR 2		
#====================================================================
setwd(gridpath)

df=c()

for ( i in 1:Nclust){
	#gsimindex=formatC(i, width=5,flag='0')
	simindex <- paste0('S',formatC(i, width=5,flag='0'))

	#read in lsm output
	sim_dat <- read.table(paste(simindex,'/out/',file1,sep=''), sep=',', header=T)

	#get memebrs
	lp = read.csv(paste0(simindex, '/listpoints.txt'))
	mem = lp$members

	# Get vector of sample
	datvec <- sim_dat[,targV] *mem
	df=cbind(df, datvec)
	}
lp = read.csv(paste0(gridpath, '/listpoints.txt'))
totalpix = sum(lp$members)
result = rowMeans(df)/totalpix
write.csv(result, paste0(targV, '_TS.csv'), row.names=FALSE, quote=FALSE)





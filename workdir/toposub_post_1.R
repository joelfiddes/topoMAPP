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
Nclust=args[2] #'/home/joel/sim/topomap_test/grid1' #
file1=args[3]
targV=args[4]

#====================================================================
# PARAMETERS FIXED
#====================================================================

#====================================================================
# TOPOSUB POSTPROCESSOR 1		
#====================================================================
setwd(gridpath)
outfile=paste(gridpath,'/meanX_',targV,'.txt',sep='')
file.create(outfile)

for ( i in 1:Nclust)

	{

	simindex=paste0('S',formatC(i, width=5,flag='0'))
	#egridpath=simindex

	#read in lsm output
	sim_dat=read.table(paste(simindex,'out',file1,sep='/'), sep=',', header=T)

	#compute mean value of target variable for sample
	meanX<-	tapply(sim_dat[,targV],sim_dat$IDpoint, FUN=mean)

	#append to master file
	write(meanX, paste(gridpath, '/meanX_', targV,'.txt', sep=''), sep=',',append=T)

	}






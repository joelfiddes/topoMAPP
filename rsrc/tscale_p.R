#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)

#SOURCE
source('./rsrc/tscale_src.R')
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1] #'/home/joel/sim/topomap_test/grid1' #
nbox=as.numeric(args[2])
pfactor=as.numeric(args[3])

#====================================================================
# PARAMETERS FIXED
#====================================================================

#**********************  SCRIPT BEGIN *******************************
setwd(wd)
coordmapfile='../eraDat/SURF.nc'

#===========================================================================
#				POINTS
#===========================================================================
#Get points meta data - loop through box directories

#make shapefile of points
#mf=read.table(metaFile, sep=',', header =T)
mf=read.csv('listpoints.txt')
npoints=dim(mf)[1]

#=======================================================================================================
#			READ FILES
#=======================================================================================================

load('../eraDat/all/pSurf') #VAR

#========================================================================
#		COMPUTE P
#========================================================================
pSurf=pSurf_cut[,nbox] #in order of mf file
pSurfm=matrix(rep(pSurf,npoints),ncol=npoints)

# if(climtolP==TRUE){
# subw=brick(subWeights)
# idgrid=raster(idgrid)
# df=data.frame(getValues(idgrid),getValues(subw))
# }
#============================================================================================
#			Apply Liston lapse
#=============================================================================================
ed=mf$eleDiff
lapseCor=(1+(pfactor*(ed/1000))/(1-(pfactor*(ed/1000))))
pSurf_lapseT=t(pSurfm)*lapseCor
pSurf_lapse=t(pSurf_lapseT)
write.table(round(pSurf_lapse,2),'pSurf_lapse.txt', row.names=F, sep=',')



#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)

#SOURCE
source('tscale_src.R')
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1] #'/home/joel/sim/topomap_test/grid1' #
nbox=as.numeric(args[2])

#====================================================================
# PARAMETERS FIXED
#====================================================================

#**********************  SCRIPT BEGIN *******************************
setwd(wd)
coordmapfile='../eraDat/SURF.nc'

#===========================================================================
#				POINTS
#===========================================================================
mf=read.csv('listpoints.txt')
npoints=dim(mf)[1]

#=======================================================================================================
#			READ FILES
#=======================================================================================================
load('../eraDat/all/gPl')
load('../eraDat/all/rhumPl') #VAR

#========================================================================
#		COMPUTE SCALED FLUXES - T,Rh,Ws,Wd,LW
#========================================================================
#get grid coordinates
coordMap=getCoordMap(coordmapfile)
x<-coordMap$xlab[nbox] # long cell
y<-coordMap$ylab[nbox]# lat cell

#extract PL data by nbox coordinates dims[data,xcoord,ycoord, pressurelevel]
gpl=gPl_cut[,x,y,]
datpl=rhumPl_cut[,x,y,] #VAR

#init dataframes
datpoints=c()
	for (i in 1:npoints){
		stationEle=mf$ele[i]
		res<-plevel2point(gdat=gpl,dat=datpl, stationEle=stationEle)
		datpoints=cbind(datpoints, res)
	}

write.table(round(datpoints,2),'rPoint.txt', row.names=F, sep=',') #VAR



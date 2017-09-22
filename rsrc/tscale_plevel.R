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
var=args[3]
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
gPl=get(load('../eraDat/all/gPl'))
dat=get(load(paste0('../eraDat/all/', var))) #VAR

#========================================================================
#		COMPUTE SCALED FLUXES - T,Rh,Ws,Wd,LW
#========================================================================
#get grid coordinates
coordMap=getCoordMap(coordmapfile)
x<-coordMap$xlab[nbox] # long cell
y<-coordMap$ylab[nbox]# lat cell

#extract PL data by nbox coordinates dims[data,xcoord,ycoord, pressurelevel]
gpl=gPl[,x,y,]
datpl=dat[,x,y,] #VAR

#init dataframes
datpoints=c()
	for (i in 1:npoints){
		stationEle=mf$ele[i]
		res<-plevel2point(gdat=gpl,dat=datpl, stationEle=stationEle)
		datpoints=cbind(datpoints, res)
	}

if (var == 'rhumPl'){outname <- 'r'}
if (var == 'tairPl'){outname <- 't'}
if (var == 'uPl'){outname <- 'u'}
if (var == 'vPl'){outname <- 'v'}
write.table(round(datpoints,2),paste0(outname,'Point.txt'), row.names=F, sep=',') #VAR



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
npoints=length(mf$id)

#=======================================================================================================
#			READ FILES
#=======================================================================================================
load('../eraDat/all/gPl')
load('../eraDat/all/tairPl') #VAR

#========================================================================
#		COMPUTE SCALED FLUXES - T,Rh,Ws,Wd,LW
#========================================================================
#get grid coordinates
coordMap=getCoordMap(coordmapfile)
x<-coordMap$xlab[nbox] # long cell
y<-coordMap$ylab[nbox]# lat cell

#extract PL data by nbox coordinates dims[data,xcoord,ycoord, pressurelevel]
gpl=gPl_cut[,x,y,]
datpl=tairPl_cut[,x,y,] #VAR

#get station attributes
stations=mf$id
lsp=mf[stations,]

#init dataframes
datpoints=c()
nameVec=c()
	for (i in 1:length(lsp$id)){
		stationEle=lsp$ele[i]
		nameVec=c(nameVec,(lsp$id[i])) #keeps track of order of 
		res<-plevel2point(gdat=gpl,dat=datpl, stationEle=stationEle)
		datpoints=cbind(datpoints, res)
	}

write.table(round(datpoints,2),'tPoint.txt', row.names=F, sep=',') #VAR



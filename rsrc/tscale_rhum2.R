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

#===========================================================================
#				POINTS
#===========================================================================
mf=read.csv('listpoints.txt')
npoints=dim(mf)[1]

#=======================================================================================================
#			READ FILES
#=======================================================================================================
file='../eraDat/PLEVEL.nc'
nc=nc_open(file)
gPl_cut=ncvar_get(nc, 'z') # [X Y Z T]
dat_cut=ncvar_get(nc, var)

#========================================================================
#		COMPUTE SCALED FLUXES - T,Rh,Ws,Wd,LW
#========================================================================
#get grid coordinates
coordMap=getCoordMap(file)
x<-coordMap$xlab[nbox] # long cell
y<-coordMap$ylab[nbox]# lat cell

#extract PL data by nbox coordinates dims[data,xcoord,ycoord, pressurelevel]
gpl=gPl_cut[x,y,,]
datpl=dat_cut[x,y,,] #VAR

#init dataframes
datpoints=c()
	for (i in 1:npoints){
		stationEle=mf$ele[i]
		res<-plevel2point2(gdat=gpl,dat=datpl, stationEle=stationEle)
		datpoints=cbind(datpoints, res)
	}

write.table(round(datpoints,2),paste0(var,'Point.txt'), row.names=F, sep=',') #VAR



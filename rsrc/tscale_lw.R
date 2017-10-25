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
svfCompute=args[3]

#====================================================================
# PARAMETERS FIXED
#====================================================================

#**********************  SCRIPT BEGIN *******************************
setwd(wd)
#coordmapfile='../eraDat/strd.nc'

#===========================================================================
#				POINTS
#===========================================================================
mf=read.csv('listpoints.txt')
npoints=dim(mf)[1]

#=======================================================================================================
#			READ FILES
#=======================================================================================================
load('../eraDat/all/lwSurf')
load('../eraDat/all/tSurf') #VAR
load('../eraDat/all/rhSurf')

t_mod=read.table('tPoint.txt', header=T, sep=',')
r_mod=read.table('rPoint.txt', header=T, sep=',')

#=======================================================================================================
#			Get correct NBOX
#=======================================================================================================
ex = raster('../spatial/eraExtent.tif')
rst = raster('../eraDat/SURF.nc')
values(rst) <- 1:ncell(rst)
n = crop(rst,ex)
vec = getValues(n)

# convert nbox from eraExtent eg 2 to nbox from ERA download
nbox = vec[nbox]
#========================================================================
#		COMPUTE SCALED FLUXES - T,Rh,Ws,Wd,LW
#========================================================================
#extract surface data by nbox  dims[data,nbox]
lwSurf=lwSurf_cut[,nbox]
tSurf=tSurf_cut[,nbox]
rhSurf=rhSurf_cut[,nbox]
	
lwPoint<-lwinTscale( tpl=t_mod,rhpl=r_mod,rhGrid=rhSurf,tGrid=tSurf, lwGrid=lwSurf, x1=0.484, x2=8)	

#correct lwin for svf

if (svfCompute==TRUE){
lwP=lwPoint %*% diag(mf$svf)
}

if (svfCompute==FALSE){
lwP <- lwPoint
}

write.table(round(lwP,2),'lwPoint.txt', row.names=F, sep=',')



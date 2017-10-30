#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)
require(insol)
#SOURCE
source('./rsrc/tscale_src.R')
source('./rsrc/surfFluxSrc.r')
source('./rsrc/solar_functions.r')
source('./rsrc/solar.r')
source('./rsrc/solar_geometry.R')
source('./rsrc/solarPartition.R')
source('./rsrc/sdirEleScale.R')
source('./rsrc/sdifSvf.R')
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1] #'/home/joel/sim/topomap_test/grid1' #
nbox=as.numeric(args[2])
swTopo=args[3]
TZ=as.numeric(args[4])
#====================================================================
# PARAMETERS FIXED
#====================================================================



#**********************  SCRIPT BEGIN *******************************
setwd(wd)
#=======================================================================================================
#			READ FILES
#=======================================================================================================
mf=read.csv('listpoints.txt')
load('../eraDat/all/swSurf')
load('../eraDat/all/toaSurf')
load('../eraDat/all/datesSurf')

#=======================================================================================================
#			Get coorect NBOX
#=======================================================================================================
ex = raster('../spatial/eraExtent.tif')
rst = raster('../eraDat/SURF.nc')
values(rst) <- 1:ncell(rst)
n = crop(rst,ex)
vec = getValues(n)

# convert nbox from eraExtent eg 2 to nbox from ERA download
nbox = vec[nbox]

#========================================================================
#		COMPUTE SW (no loop needed)
#========================================================================
npoints=dim(mf)[1]
sw=swSurf_cut[,nbox]
swm=matrix(rep(sw,npoints),ncol=npoints) #make matrix with ncol =points, repeats of each nbox vector
toa=toaSurf_cut[,nbox]
toam=matrix(rep(toa,npoints),ncol=npoints)
dd=as.POSIXct(datesSurf_cut, tz="GMT")

if(swTopo==TRUE){
#START
#partition
sdif=solarPartition(swPoint=swm,toaPoint=toam, out='dif')
sdir=solarPartition(swPoint=swm,toaPoint=toam, out='dir')

#elevation scale of SWin_dir (additative)
sdirScale=sdirEleScale(sdirm=sdir,toaPoint=toam,dates=dd, mf=mf)

#topo correction to SWin_dif - reduce according to svf
sdifcor=sdifSvf(sdifm=sdif, mf=mf)

#corrects direct beam component for solar geometry, cast shadows and self shading
sdirTopo=solarGeom(mf=mf,dates=dd, sdirm=sdirScale, tz=TZ)

#add both components
sglobal=sdirTopo+sdifcor
#FINISH
write.table(sglobal,'sol.txt', row.names=F, sep=',')
write.table(sdirTopo, 'solDir.txt', row.names=F, sep=',')
write.table(sdifcor,'solDif.txt', row.names=F, sep=',')

}

if(swTopo==FALSE){
#old combined function replaced by functions between START and FINISH
sol=solarCompute(swin=swm,toa=toam, dates=dd,mf=mf, tz=TZ)
write.table(round(sol,2),  'sol.txt', row.names=F, sep=',')
}

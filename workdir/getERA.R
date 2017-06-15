#====================================================================
# Setup
#====================================================================
#INFO
# READ: https://software.ecmwf.int/wiki/display/WEBAPI/Access+ECMWF+Public+Datasets
# register
# set up $HOME/.ecmwfapirc

#DEPENDENCY
require(raster)

#SOURCE
source('getERA_src.R')

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]#"/home/joel/sim/topomap_test/"
runtype=args[2]#"bbox" #"points or "bbox"
startDate=args[3]#"20121230/to/20121231"# date range yyyymmdd
endDate=args[4] #20121231
grid=args[5]
#lon=args[5]
#lat=argsw[6]

#====================================================================
# Parameters fixed
#====================================================================
eraDir=paste0(wd, '/eraDat')
parNameSurf=c( 'dt', 'strd', 'ssrd', 'p', 't', 'toa')
parCodeSurf=c(168,175,169,228,167,212)
parNamePl=c('gpot','tpl','rhpl','upl','vpl')
parCodePl=c(129,130,157,131,132)
plev= '500/650/775/850/925/1000'	#pressure levels (mb), only written if levtype=pl

#**********************  SCRIPT BEGIN *******************************

#===============================================================================
#				CONSTRUCT DATE
#===============================================================================
#add one day buffer to ensure all required timestamp present during processing
startDatebuff=format((as.Date(startDate)-1),'%Y%m%d')
endDatebuff=format((as.Date(endDate)+1),'%Y%m%d')
dd=paste0(startDatebuff,'/to/',endDatebuff) # "20121230/to/20121231"
print(dd)

#===============================================================================
#				CONSTRUCT GRID RESOL PARAMETER
#===============================================================================
grd=paste0(grid,'/',grid)	# resolution long/lat (0.75/0.75) or grid single integer eg 80

#===============================================================================
#				GET BBOX FROM MF
#===============================================================================
#tol=0.1
#n=max(mf$lat+tol)
#s=min(mf$lat-tol)
#e=max(mf$lon+tol)
#w=min(mf$lon-tol)

#===============================================================================
#				GET BBOX FROM raster
#===============================================================================
#if (runtype == "bbox"){
eraExtent=raster(paste0(wd,'/spatial/eraExtent.tif'))
tol=as.numeric(grid)/2 #converts extent based on boundary to extent based on grid centres
xtent=extent(eraExtent)
n=xtent@ymax-tol
s=xtent@ymin+tol
e=xtent@xmax-tol
w=xtent@xmin+tol
ar= paste(n,w,s,e,sep='/')# region of interest N/W/S/E this corresponds to box centres
#}

print(paste0('Requesting ERA-grids within extent', ar))
#===============================================================================
#				 PARAMETERS SURFACE
#===============================================================================
t='00/12'#00/12 gives 3hr data for sfc retrieval ; 00/06/12/18 gives 6hr data for pl retrieval (3hr not possible) ; 00/12 for accumulated
stp='3/6/9/12'#3/6/9/12 gives 3hr data for sfc ; 0 gives 6hr data for pl retrieval (3hr not possible)
lt='sfc'# sfc=surface or pl=pressure level
typ='fc'#an=analysis or fc=forecast, depends on parameter - check on ERA gui.

#===============================================================================
#				 PARAMETERS SURFACE
#===============================================================================
dir.create(eraDir)
#===============================================================================
#				GET DATA SURFACE
#===============================================================================
for( i in 1:length(parNameSurf)){
par= parCodeSurf[i]# parameter code - check on ERA gui.
tar=paste(parNameSurf[i],'.nc', sep='')
getERA(dd=dd, t=t, grd=grd, stp=stp, lt=lt,typ=typ,par=par,ar=ar,tar=tar,plev=plev,workd=eraDir)
}

#===============================================================================
#				 PARAMETERS PRESSURE LEVEL
#===============================================================================
t='00/06/12/18'#00/12 gives 3hr data for sfc retrieval ; 00/06/12/18 gives 6hr data for pl retrieval (3hr not possible) ; 00/12 for accumulated
stp='0'#3/6/9/12 gives 3hr data for sfc ; 0 gives 6hr data for pl retrieval (3hr not possible)
lt='pl'# sfc=surface or pl=pressure level
typ='an'#an=analysis or fc=forecast, depends on parameter - check on ERA gui.

#===============================================================================
#				GET DATA PRESSURE LEVEL
#===============================================================================
for( i in 1:length(parNamePl)){
par= parCodePl[i]# parameter code - check on ERA gui.
tar=paste(parNamePl[i],'.nc', sep='')
getERA(dd=dd, t=t, grd=grd, stp=stp, lt=lt,typ=typ,par=par,ar=ar,tar=tar,plev=plev,workd=eraDir)
}

#===============================================================================
#				CLEAN UP GRIB FILES
#===============================================================================
# grb=list.files(workd, pattern='.grb')

# for(i in 1:length(grb)){
# system(paste('rm ',workd,'/',grb[i],sep=''))
# }

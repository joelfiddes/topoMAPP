#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)

#SOURCE
source('./rsrc/getERA_src.R')
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
grid=args[2]
#====================================================================
# PARAMETERS FIXED
#====================================================================

#**********************  SCRIPT BEGIN *******************************
print(paste0('clipping domain for ERA-grid resolution: ', grid))
#====================================================================
# CLIP TO NEAREST ERA EXTENT
#====================================================================
#parameters
setwd(wd)
dir.create(paste0(wd, '/spatial'))
ele=raster('predictors/dem.tif')
tol=0 #must be greater than 0.5*box resolution to get correct extent in degrees
xtent=extent(ele)
n=xtent@ymax+tol
s=xtent@ymin-tol
e=xtent@xmax+tol
w=xtent@xmin-tol
ar= paste(n,w,s,e,sep='/')# region of interest N/W/S/E this corresponds to box centres
t='12'#00/12 gives 3hr data for sfc retrieval ; 00/06/12/18 gives 6hr data for pl retrieval (3hr not possible) ; 00/12 for accumulated
stp='0'#3/6/9/12 gives 3hr data for sfc ; 0 gives 6hr data for pl retrieval (3hr not possible)
lt='sfc'# sfc=surface or pl=pressure level
typ='an'#an=analysis or fc=forecast, depends on parameter - check on ERA gui.
par= 129 # geopotential height used to compute upper limit of pressure levels
tar='spatial/eraExtent.nc'
grd=paste0(grid,'/',grid)
dd='1989-01-01'

#request to EWMF
print('Requesting data from ECWMF.....')
t1=Sys.time()
getERA(dd=dd, t=t, grd=grd, stp=stp, lt=lt,typ=typ,par=par,ar=ar,tar=tar,plev=NULL,workd=wd)
t2 <- Sys.time()
t3 <- t2 - t1
print('Request complete')
print(t3)
eraExtent=raster('spatial/eraExtent.nc')

# era data is given in gaussian grid ie degreed east range is 0-360 not -180-180, in case of longitude > 180, subtract 360
if (eraExtent@extent@xmin > 180)
	{ 
	eraExtent@extent@xmin <- eraExtent@extent@xmin - 360
	}
if (eraExtent@extent@xmax > 180)
	{ 
	eraExtent@extent@xmax <- eraExtent@extent@xmax - 360
	}
# crop domain to era grids completely covered by DEM - this will lose margin of dem
# accuracy of these two extents is around half DEm pixel = 15m ie can be 15m difference in boudaries

newExtent=crop(eraExtent,ele,snap='in')
newDEM=crop(ele,newExtent)
writeRaster(newExtent, 'spatial/eraExtent.tif', overwrite=TRUE)
writeRaster(newDEM, 'predictors/ele.tif', overwrite=TRUE)




#cleanup
system('rm predictors/dem.tif')
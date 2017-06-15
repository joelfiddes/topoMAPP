#====================================================================
# SETUP
#====================================================================
#INFO
# Preprocess ERA-Interim fields

#DEPENDENCY
require(ncdf4)

#SOURCE
source('tscale_src.R')

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]

startDate=args[2] #'2012-12-30 00:00:00' #start cut of driving climate (ERA format)	#yyyy-mmd-d h:m:s
endDate=args[3] #'2012-12-31 00:00:00'
#====================================================================
# PARAMETERS FIXED
#====================================================================
#PRESSURE LEVEL FIELDS (AND DEWT)
infileG='gpot.nc'
infileT='tpl.nc'
infileRh='rhpl.nc'
infileU='upl.nc'
infileV='vpl.nc'
infileD='dt.nc'

#SURFACE FIELDS
lwFile='strd.nc'
swFile='ssrd.nc'
pFile='p.nc'
tFile='t.nc'
toaFile='toa.nc'

# Output dirs
outRootPl='pressurelevel/'
outRootSurf='surface/'
outRootmet='all/'

step=3 					#time step of accumulated fields

#**********************  SCRIPT BEGIN *******************************
setwd(paste0(wd, '/eraDat'))
dir.create(outRootPl, showWarnings=FALSE)
dir.create(outRootSurf, showWarnings=FALSE)
dir.create(outRootmet,  showWarnings=FALSE)


########################################################################################################
#													
#				TOPOSCALE PREPROCESS DATA
#									
########################################################################################################
#interpolate to 3h timestep
#includes dewT (surface field) which comes at 6h

#=======================================================================================================
#			INTERPOLATE 6H FIELDS TO 3H
#=======================================================================================================

#INTERPOLATE TIME
nc=nc_open(infileT)
time = ncvar_get( nc,'time')
time2=interp6to3(time) #accepts vector
z <- time2*60*60 #make seconds
origin=substr(nc$dim$time$units,13,22)
datesPl<-ISOdatetime(origin,0,0,0,0,0,tz='UTC') + z #dates sequence
save(datesPl, file=paste(outRootPl, '/dates', sep=''))
#write.table(dates,paste(outRootPl, '/dates', sep=''), sep=',', row.names=F, col.names=F)

#INTERPOLATE GRAVITY
nc=nc_open(infileG)
var=names(nc$var)

dat = ncvar_get( nc,var)
datInterp=apply(X=dat, MARGIN=c(1,2,3), FUN=interp6to3)
save(datInterp, file=paste(outRootPl, '/gPl', sep=''))

#INTERPOLATE TAIR
nc=nc_open(infileT)
var=names(nc$var)

dat = ncvar_get( nc,var)
datInterp=apply(X=dat, MARGIN=c(1,2,3), FUN=interp6to3)
save(datInterp, file=paste(outRootPl, '/tairPl', sep=''))

#INTERPOLATE RHUM
nc=nc_open(infileRh)
var=names(nc$var)

dat = ncvar_get( nc,var)
datInterp=apply(X=dat, MARGIN=c(1,2,3), FUN=interp6to3)
save(datInterp, file=paste(outRootPl, '/rhumPl', sep=''))

#INTERPOLATE U
nc=nc_open(infileU)
var=names(nc$var)

dat = ncvar_get( nc,var)
datInterp=apply(X=dat, MARGIN=c(1,2,3), FUN=interp6to3)
save(datInterp, file=paste(outRootPl, '/uPl', sep=''))

#INTERPOLATE V
nc=nc_open(infileV)
var=names(nc$var)

dat = ncvar_get( nc,var)
datInterp=apply(X=dat, MARGIN=c(1,2,3), FUN=interp6to3)
save(datInterp, file=paste(outRootPl, '/vPl', sep=''))

#INTERPOLATE d2m
nc=nc_open(infileD)
var=names(nc$var)

dat = ncvar_get( nc,var)
datInterp=apply(X=dat, MARGIN=c(1,2), FUN=interp6to3)
save(datInterp, file=paste(outRootPl, '/dewT', sep=''))

########################################################################################################
#													
#				PREPROCESS SURFACE FIELDS
#									
########################################################################################################

#convert accumulated values to timestep averages
#precip units changed
#3d to 2d matrix

#=======================================================================================================
#			COORDMAP
#=======================================================================================================
file=lwFile
coordMap=getCoordMap(file)
step=step

#=======================================================================================================
#			CONVERT ACCUMULATED VALUES TO TIMESTEP AVERAGES AND SHIFT
#=======================================================================================================

#=======================================================================================================
#			SURFACE FIELDS TIME VECTOR
#=======================================================================================================

nc=nc_open(lwFile)
time = ncvar_get( nc,'time')
#origin =unlist(strsplit(nc$dim$time$units,'hours since '))[2]
origin=substr(nc$dim$time$units,13,22)

z <- time*60*60 #make seconds
dates<-ISOdatetime(origin,0,0,0,0,0,tz='UTC') + z #dates sequence
datesSurf=dates[1:length(dates)-1] #remove last time value to account for acummulated to average value conversion

#=======================================================================================================
#			LWIN
#=======================================================================================================
nc=nc_open(lwFile)
var=names(nc$var)

indat = ncvar_get( nc, var)

#could vectorise but quick anyway 
lwgridAv=c()
	for(i in coordMap$cells){
	x=coordMap$xlab[i]
	y=coordMap$ylab[i]
	lgav=accumToInstERA_simple(inDat=indat[x,y,], step=step)
	lwgridAv=cbind(lwgridAv,lgav)
	}
#interpolate to original timestep
lwgridAdj=c()
	for(i in coordMap$cells){
	lAdj=adjAccum(lwgridAv[,i])
	lwgridAdj=cbind(lwgridAdj,lAdj)
	}
lwgridAdj=lwgridAv
#=======================================================================================================
#			SWIN
#=======================================================================================================
nc=nc_open(swFile)
var=names(nc$var)

indat = ncvar_get( nc, var)

#could vectorise but quick anyway 
swgridAv=c()
	for(i in coordMap$cells){
	x=coordMap$xlab[i]
	y=coordMap$ylab[i]
	sgav=accumToInstERA_simple(inDat=indat[x,y,], step=step)
	swgridAv=cbind(swgridAv,sgav)
	}

#interpolate to original timestep
swgridAdj=c()
	for(i in coordMap$cells){
	sAdj=adjAccum(swgridAv[,i])
	swgridAdj=cbind(swgridAdj,sAdj)
	}
swgridAdj=swgridAv
#=======================================================================================================
#			TOA
#=======================================================================================================
nc=nc_open(toaFile)
var=names(nc$var)

indat = ncvar_get( nc, var)

#could vectorise but quick anyway 
toagridAv=c()
	for(i in coordMap$cells){
	x=coordMap$xlab[i]
	y=coordMap$ylab[i]
	togav=accumToInstERA_simple(inDat=indat[x,y,], step=step)
	toagridAv=cbind(toagridAv,togav)
	}

#interpolate to original timestep
toagridAdj=c()
	for(i in coordMap$cells){
	toAdj=adjAccum(toagridAv[,i])
	toagridAdj=cbind(toagridAdj,toAdj)
	}

toagridAdj=toagridAv
#=======================================================================================================
#			PRECIP
#=======================================================================================================
nc=nc_open(pFile)
var=names(nc$var)

indat = ncvar_get( nc, var)

#could vectorise but quick anyway 
pgridAv=c()
	for(i in coordMap$cells){
	x=coordMap$xlab[i]
	y=coordMap$ylab[i]
	pgav=accumToInstERA_simple(inDat=indat[x,y,], step=step)
	pgridAv=cbind(pgridAv,pgav)
	}
#interpolate to original timestep
pgridAdj=c()
	for(i in coordMap$cells){
	pAdj=adjAccum(pgridAv[,i])
	pgridAdj=cbind(pgridAdj,pAdj)
	}

pgridAdj=pgridAv
#convert m/s -> mm/hr
pgridAdjHr=pgridAdj*1000*60*60


#=======================================================================================================
#			WRITE FILES
#=======================================================================================================
save(datesSurf, file=paste(outRootSurf, '/dates', sep=''))
save(lwgridAdj, file=paste(outRootSurf, '/lwgrid', sep=''))
save(swgridAdj, file=paste(outRootSurf, '/swgrid', sep=''))
save(pgridAdjHr, file=paste(outRootSurf, '/pgrid', sep=''))
save(toagridAdj, file=paste(outRootSurf, '/toagrid', sep=''))

########################################################################################################
#													
#				CUT FIELDS TO COMMON PERIOD
#									
########################################################################################################

#read dates
load(file=paste(outRootPl, '/dates', sep=''))
#datesPl=dPl$V1 #"1996-01-01 UTC" -- "2009-12-31 18:00:00 UTC"
load(file=paste(outRootSurf, '/dates', sep=''))
#datesSurf=dSurf$V1 #1996-01-01 03:00:00 --2011-12-31 21:00:00

#format dates to include HMS
startDateHMS=as.character(format(as.Date(startDate,'%Y-%m-%d'), '%Y-%m-%d %H:%M:%S'))
endDateHMS=as.character(format(as.Date(endDate,'%Y-%m-%d'), '%Y-%m-%d %H:%M:%S'))

#cut dates - output files should be identical
n1p=which(as.character(datesPl)==startDateHMS)
n2p=which(as.character(datesPl)==endDateHMS)
datesPl_cut=as.character(datesPl[n1p:n2p])
save(datesPl_cut, file=paste(outRootmet, '/datesPl', sep=''))

n1s=which(as.character(datesSurf)==startDateHMS)
n2s=which(as.character(datesSurf)==endDateHMS)
datesSurf_cut=as.character(datesSurf[n1s:n2s])
save(datesSurf_cut, file=paste(outRootmet, '/datesSurf', sep=''))


#PRESSURE LEVEL FIELDS
load(paste(outRootPl, '/gPl', sep=''))
gPl_cut=datInterp[n1p:n2p,,,]
save(gPl_cut, file=paste(outRootmet, '/gPl', sep=''))

load(paste(outRootPl, '/tairPl', sep=''))
tairPl_cut=datInterp[n1p:n2p,,,]
save(tairPl_cut, file=paste(outRootmet, '/tairPl', sep=''))

load(paste(outRootPl, '/rhumPl', sep=''))
rhumPl_cut=datInterp[n1p:n2p,,,]
save(rhumPl_cut, file=paste(outRootmet, '/rhumPl', sep=''))

load(paste(outRootPl, '/uPl', sep=''))
uPl_cut=datInterp[n1p:n2p,,,]
save(uPl_cut, file=paste(outRootmet, '/uPl', sep=''))

load(paste(outRootPl, '/vPl', sep=''))
vPl_cut=datInterp[n1p:n2p,,,]
save(vPl_cut, file=paste(outRootmet, '/vPl', sep=''))

load(paste(outRootPl, '/dewT', sep=''))
dewT_cut=datInterp[n1p:n2p,,]
save(dewT_cut, file=paste(outRootmet, '/dewTSurf', sep=''))


#SURFACE FIELDS
load( paste(outRootSurf, '/lwgrid', sep=''))
lwSurf_cut=lwgridAdj[n1s:n2s,]
load( paste(outRootSurf, '/swgrid', sep=''))
swSurf_cut=swgridAdj[n1s:n2s,]
load(paste(outRootSurf, '/pgrid', sep=''))
pSurf_cut=pgridAdjHr[n1s:n2s,]
load(paste(outRootSurf, '/toagrid', sep=''))
toaSurf_cut=toagridAdj[n1s:n2s,]

save(lwSurf_cut, file=paste(outRootmet, '/lwSurf', sep=''))
save(swSurf_cut, file=paste(outRootmet, '/swSurf', sep=''))
save(pSurf_cut, file=paste(outRootmet, '/pSurf', sep=''))
save(toaSurf_cut, file=paste(outRootmet, '/toaSurf', sep=''))
########################################################################################################
#
#			COMPUTE SURFACE RELATIVE HUMIDITY (for LWin computation)
#
########################################################################################################
#read data
load(file=paste(outRootmet, '/dewTSurf', sep=''))
td=dewT_cut
nc=nc_open(tFile)
var=names(nc$var)

t = ncvar_get( nc, var)

#convert to 2d matrix
tgrid=c()
tdgrid=c()
	for(i in coordMap$cells){
	x=coordMap$xlab[i]
	y=coordMap$ylab[i]
	tg=t[x,y,]#nb order of dimensions differs
	tdg=td[,x,y] #nb order of dimensions differs
	tgrid=cbind(tgrid,tg)
	tdgrid=cbind(tdgrid,tdg)
	}

#cut tair data
tSurf_cut=tgrid[n1s:n2s,]

#compute Rh at surface
rhSurf_cut=relHumCalc(tair=tSurf_cut,tdew=tdgrid)
rhSurf_cut[rhSurf_cut>100]<-100 #constrain to 100% Rh
save(rhSurf_cut, file=paste(outRootmet, '/rhSurf', sep=''))
save(tSurf_cut, file=paste(outRootmet, '/tSurf', sep=''))


########################################################################################################
#
#			CLEAN UP
#
########################################################################################################
#system('rm -r /home/joel/data/tscale/tmp/pressurelevel/')
#system('rm -r /home/joel/data/tscale/tmp/surface')


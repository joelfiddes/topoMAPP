#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)
require(ncdf4)

#SOURCE
source('./rsrc/tscale_src.R')
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1] #
nbox=as.numeric(args[2])
#gridEle=args[3]
#====================================================================
# PARAMETERS FIXED
#====================================================================

#**********************  SCRIPT BEGIN *******************************


########################################################################################################
#
#			TOPOSCALE SWin
#
########################################################################################################
#===========================================================================
#				SETUP
#===========================================================================
# wd<-getwd()
# root=paste(wd,'/',sep='')
# parfile=paste(root,'/src/TopoAPP/parfile.r', sep='')
# source(parfile) #give nbox and epath packages and functions
# nbox<-nboxSeq
# simindex=formatC(nbox, width=5,flag='0')
# spath=paste(epath,'/result/B',simindex,sep='') #simulation path

# setup=paste(root,'/src/TopoAPP/expSetup1.r', sep='')
# source(setup) #give tFile outRootmet

#===========================================================================
#				COMPUTE POINTS META DATA - eleDiff, gridEle, Lat, Lon 
#===========================================================================
setwd(wd)
file='../eraDat/SURF.nc'
nc=nc_open(file)
mf=read.csv('listpoints.txt')
npoints=length(mf$ele)
eraBoxEle=read.table('../eraEle.txt',sep=',', header=FALSE)[,1]

#find ele diff station/gidbox
#eraBoxEle<-getEraEle(dem=eraBoxEleDem, eraFile=tFile) # $masl
gridEle<-rep(eraBoxEle[nbox],length(mf$ele))
mf$gridEle<-round(gridEle,2)
eleDiff=mf$ele-mf$gridEle
mf$eleDiff<-round(eleDiff,2)
#get grid coordinates
coordMap=getCoordMap(file)
x<-coordMap$xlab[nbox] # long cell
y<-coordMap$ylab[nbox]# lat cell

#get long lat centre point of nbox (for solar calcs)
lat=ncvar_get(nc, 'latitude')
lon=ncvar_get(nc, 'longitude')
latn=lat[y]
lonn=lon[x]
mf$boxlat=rep(latn,length(mf$ele))
mf$boxlon=rep(lonn,length(mf$ele))

write.csv(mf, 'listpoints.txt', row.names=FALSE)


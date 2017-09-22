########################################################################################################
#
#			TOPOSCALE
#
########################################################################################################
#===========================================================================
#				SETUP
#===========================================================================
wd<-getwd()
root=paste(wd,'/',sep='')
parfile=paste(root,'/src/TopoAPP/parfile.r', sep='')
source(parfile) #give nbox and epath packages and functions
nbox<-nboxSeq
simindex=formatC(nbox, width=5,flag='0')
spath=paste(epath,'/result/B',simindex,sep='') #simulation path

setup=paste(root,'/src/TopoAPP/expSetup1.r', sep='')
source(setup) #give tFile outRootmet

file=lwFile
coordMap=getCoordMap(file)
nc=open.ncdf(infileT)

#===========================================================================
#				POINTS
#===========================================================================
#Get points meta data - loop through box directories

#make shapefile of points
#mf=read.table(metaFile, sep=',', header =T)
mf=read.table(paste(spath,'/listpoints.txt',sep=''),header=T,sep=',')
npoints=length(mf$id)

#find ele diff station/gidbox
eraBoxEle<-getEraEle(dem=eraBoxEleDem, eraFile=tFile) # $masl
gridEle<-rep(eraBoxEle[nbox],length(mf$id))
mf$gridEle<-gridEle
eleDiff=mf$ele-mf$gridEle
mf$eleDiff<-eleDiff



#=======================================================================================================
#			READ FILES
#=======================================================================================================

load(paste(outRootmet,'/pSurf',sep=''))

#========================================================================
#		COMPUTE P
#========================================================================
pSurf=pSurf_cut[,nbox] #in order of mf file
pSurfm=matrix(rep(pSurf,npoints),ncol=npoints)

if(climtolP==TRUE){
subw=brick(subWeights)
idgrid=raster(idgrid)
df=data.frame(getValues(idgrid),getValues(subw))
}
#============================================================================================
#			Apply Liston lapse
#=============================================================================================
ed=mf$eleDiff
lapseCor=(1+(pfactor*(ed/1000))/(1-(pfactor*(ed/1000))))
pSurf_lapseT=t(pSurfm)*lapseCor
pSurf_lapse=t(pSurf_lapseT)
write.table(pSurf_lapse,paste(spath,  '/pSurf_lapse.txt',sep=''), row.names=F, sep=',')



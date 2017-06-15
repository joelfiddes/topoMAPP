########################################################################################################
#
#			TOPOSCALE LWin
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

t_mod=read.table(paste(spath,  '/tPoint.txt',sep=''), header=T, sep=',')
r_mod=read.table(paste(spath,  '/rPoint.txt',sep=''), header=T, sep=',')


#===========================================================================
#				POINTS
#===========================================================================
mf=read.table(paste(spath,'/listpoints.txt',sep=''),header=T,sep=',')

#=======================================================================================================
#			READ FILES
#=======================================================================================================
load(paste(outRootmet,'/lwSurf',sep=''))
load(paste(outRootmet,'/tSurf',sep=''))
load(paste(outRootmet,'/rhSurf',sep=''))

#========================================================================
#		COMPUTE SCALED FLUXE
#========================================================================	
#extract surface data by nbox  dims[data,nbox]
lwSurf=lwSurf_cut[,nbox]
tSurf=tSurf_cut[,nbox]
rhSurf=rhSurf_cut[,nbox]
	
lwPoint<-lwinTscale( tpl=t_mod,rhpl=r_mod,rhGrid=rhSurf,tGrid=tSurf, lwGrid=lwSurf, x1=0.484, x2=8)	

#correct lwin for svf
lwP=lwPoint %*% diag(mf$svf)

write.table(lwP,paste(spath,  '/lwPoint.txt',sep=''), row.names=F, sep=',')

		



#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)
#SOURCE
source("./rsrc/toposub_src.R")
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
gridpath=args[1]
Nclust=args[2]
targV=args[3]
svfCompute=args[4]
#Nclust=args[2] #'/home/joel/sim/topomap_test/grid1' #

#====================================================================
# PARAMETERS FIXED
#====================================================================
#====================================================================
# PARAMETERS FIXED
#====================================================================
#nFuzMem=10 #number of members to retain
iter.max=50	# maximum number of iterations of clustering algorithm
nRand=100000	# sample size
#fuzzy.e=1.4 	# fuzzy exponent
nstart1=10 	# nstart for sample kmeans [find centers]
nstart2=1 	# nstart for entire data kmeans [apply centers]
thresh_per=0.001 # needs experimenting with
samp_reduce=FALSE
#====================================================================
#			TOPOSUB PREPROCESSOR INFORMED SAMPLING		
#====================================================================
setwd(gridpath)

#set tmp directory for raster package
#setOptions(tmpdir=paste(gridpath, '/tmp', sep=''))

#read listpoint
listpoints=read.csv(paste(gridpath,'/listpoints.txt',sep=''))


setwd(paste0(gridpath,'/predictors'))
predictors=list.files( pattern='*.tif$')

print(predictors)
rstack=stack(predictors)

gridmaps<- as(rstack, 'SpatialGridDataFrame')

#decompose aspect
res=aspect_decomp(gridmaps$asp)
gridmaps$aspC<-res$aspC
gridmaps$aspS<-res$aspS

#define new predNames (aspC, aspS)
allNames<-names(gridmaps@data)
predNames2 <- allNames[which(allNames!='surface'&allNames!='asp')]



#initialise file to write to
pvec<-rbind(predNames2)
x<-cbind("tv",pvec,'r2')
write.table(x, paste(gridpath,"/coeffs.txt",sep=""), sep=",",col.names=F, row.names=F)
write.table(x, paste(gridpath,"/decompR.txt",sep=""), sep=",",col.names=F, row.names=F)

# read mean values of targV
meanX=read.table( paste(gridpath, '/meanX_', targV,'.txt', sep=''), sep=',')

# compute coeffs of linear model
coeffs=linMod2(meanX=meanX,listpoints=listpoints, predNames=predNames2,col=targV, svfCompute=FALSE) #linear model

write(coeffs, paste(gridpath,"/coeffs.txt",sep=""),ncolumns=7, append=TRUE, sep=",") # 6 cols if no svf
weightsMean<-read.table(paste(gridpath,"/coeffs.txt",sep=""), sep=",",header=T)

#==========mean coeffs table for multiple preds ================================
#coeffs_vec=meanCoeffs(weights=weights, nrth=nrth) #rmove nrth
##y<-rbind(predNames)
#y <- cbind(y,'r2')
#write.table(y, paste(egridpath,"/coeffs_Mean.txt",sep=""), sep=",",col.names=F, row.names=F)
#write(coeffs_vec, paste(egridpath,"/coeffs_Mean.txt",sep=""),ncolumns=(length(predNames)+1), append=TRUE, sep=",")
#weightsMean<-read.table(paste(egridpath,"/coeffs_Mean.txt",sep=""), sep=",",header=T)	
	
samp_dat<-sampleRandomGrid( nRand=nRand, predNames=predNames2)

#use original samp_dat
informScaleDat1=informScale(data=samp_dat, pnames=predNames2,weights=weightsMean)

#remove NA's from dataset (not tolerated by kmeans)
informScaleDat_samp=na.omit(informScaleDat1)

#kmeans on sample
clust1=Kmeans(scaleDat=informScaleDat_samp,iter.max=iter.max,centers=Nclust, nstart=nstart1)
#scale whole dataset
informScaleDat2=informScale(data=gridmaps@data, pnames=predNames2,weights=weightsMean)

#remove NA's from dataset (not tolerated by kmeans)
informScaleDat_all=na.omit(informScaleDat2)
#kmeans whole dataset
clust2=Kmeans(scaleDat=informScaleDat_all,iter.max=iter.max,centers=clust1$centers, nstart=nstart2)

#remove small samples, redist to nearestneighbour attribute space
if(samp_reduce==TRUE){
clust3=sample_redist(pix= length(clust2$cluster),samples=Nclust,thresh_per=thresh_per, clust_obj=clust2)# be careful, samlple size not updated only clust2$cluster changed
}else{clust2->clust3}

#confused by these commented out lines
#gridmaps$clust <- clust3$cluster
#write.asciigrid(gridmaps["landform"], paste(egridpath,"/landform_",Nclust,".tif",sep=''),na.value=-9999)

#make map of clusters 

# new method to deal with NA values 
#vector of non NA index
n2=which(is.na(informScaleDat2$aspC)==FALSE)
#make NA vector
vec=rep(NA, dim(informScaleDat2)[1])
#replace values
vec[n2]<-as.factor(clust3$cluster)


#**CLEANUP**
rm(informScaleDat_all)
#gc()

#gridmaps$landform <- as.factor(clust3$cluster)
gridmaps$landform <-vec
#writeRaster(raster(gridmaps["landform"]), paste(spath,"/landform_",Nclust,".tif",sep=''),NAflag=-9999,overwrite=T)
rst=raster(gridmaps["landform"])
writeRaster(rst, paste0(gridpath,"/landform.tif"),NAflag=-9999,overwrite=T)
pdf(paste0(gridpath,'/landformsInform.pdf'))
plot(rst)
dev.off()
samp_mean <- aggregate(gridmaps@data[predNames2], by=list(gridmaps$landform), FUN='mean')
samp_sd <- aggregate(gridmaps@data[predNames2], by=list(gridmaps$landform), FUN='sd')
samp_sum <- aggregate(gridmaps@data[predNames2], by=list(gridmaps$landform), FUN='sum')

#replace asp with correct mmean asp
asp=meanAspect(dat=gridmaps@data, agg=gridmaps$landform)
samp_mean$asp<-asp
#issue with sd and sum of aspect - try use 'circular'

#remove this unecessary (?) I/O
#write to disk for cmeans(replaced by kmeans 2)
#write.table(samp_mean,paste(spath, '/samp_mean.txt' ,sep=''), sep=',', row.names=FALSE)
#write.table(samp_sd,paste(spath, '/samp_sd.txt' ,sep=''), sep=',', row.names=FALSE)

#make driving topo data file	
#lsp <- listpointsMake(samp_mean=samp_mean, samp_sum=samp_sum)


#construct listpoints table
mem<-samp_sum[2]/samp_mean[2]
members<-mem$ele
colnames(samp_mean)[1] <- "id"
lsp<-data.frame(members,samp_mean)

write.csv(round(lsp,2),paste0(gridpath, '/listpoints.txt'), row.names=FALSE)

pdf(paste0(gridpath, '/sampleDistributionsInform.pdf'), width=6, height =12)
par(mfrow=c(3,1))
hist(lsp$ele)
hist(lsp$slp)
hist(lsp$asp)
hist(lsp$members)
dev.off()



print("TOPOSUB INFORM COMPLETE!")






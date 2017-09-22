#====================================================================
# SETUP
#====================================================================
#INFO
#in = ele,asp,slp (minimum)
#out = listpoints.txt file, landforms.tif map

#DEPENDENCY
require(rgdal)
require(raster)

#SOURCE
source("./rsrc/toposub_src.R")

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
gridpath=args[1]
Nclust=args[2]
#Ngrid=args[3]
# # test if there is at least one argument: if not, return an error
# if (length(args)==0) {
#  # stop("At least one argument must be supplied (Nclust)", call.=FALSE)} 
# print("WARNING: using default value Nclust=10")
# args[1] = 10} 
# #else if (length(args)==1) {
#   # default output file
#  # args[1] = 10
# #}

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

#**********************  SCRIPT BEGIN *******************************
print(paste0('Running TOPOSUB on ',Nclust,' samples'))

#==============================================================================
# TopoSUB preprocessor
#==============================================================================
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

#sample inputs
#need to generalise to accept 'data' argument
samp_dat<-sampleRandomGrid( nRand=nRand, predNames=predNames2)

# find number of clusters required
#if (findn==1){Nclust=findN(scaleDat=scaleDat, nMax=1000,thresh=0.05)}

#make scaled (see r function 'scale()')data frame of inputs 
scaleDat_samp= simpleScale(data=samp_dat, pnames=predNames2)

#random order of kmeans init conditions (variable order) experiment
#if(randomKmeansInit==T){
#cbind(scaleDat_samp[5],scaleDat_samp[4], scaleDat_samp[3], scaleDat_samp[2], scaleDat_samp[1])->scaleDat_samp}

#remove NA's from dataset (not tolerated by kmeans)
scaleDat_samp2=na.omit(scaleDat_samp)
#kmeans on sample

#clust1=Kmeans(scaleDat=scaleDat_samp2,iter.max=iter.max,centers=Nclust, nstart=nstart1)
clust1 <- kmeans(x=scaleDat_samp2, centers=Nclust, iter.max = iter.max, nstart = nstart1, trace=FALSE)
#http://stackoverflow.com/questions/21382681/kmeans-quick-transfer-stage-steps-exceeded-maximum


     ## S3 method for class 'kmeans'

#**CLEANUP**
rm(scaleDat_samp)
rm(scaleDat_samp2)
#rm(samp_dat)
gc()


#scale whole dataset
scaleDat_all= simpleScale(data=gridmaps@data, pnames=predNames2)

#remove NA's from dataset (not tolerated by kmeans)
scaleDat_all2=na.omit(scaleDat_all)
#kmeans whole dataset

#clust2=Kmeans(scaleDat=scaleDat_all2,iter.max=iter.max,centers=clust1$centers, nstart=nstart2)
clust2 <- kmeans(x=scaleDat_all2, centers=clust1$centers, iter.max = iter.max, nstart = nstart2, trace=FALSE)
#http://stackoverflow.com/questions/21382681/kmeans-quick-transfer-stage-steps-exceeded-maximum

#**CLEANUP**
rm(scaleDat_all2)
rm(clust1)
gc()

#remove small samples, redist to nearestneighbour attribute space
if(samp_reduce==TRUE){
clust3=sample_redist(pix= length(clust2$cluster),samples=Nclust,thresh_per=thresh_per, clust_obj=clust2)# be careful, samlple size not updated only clust2$cluster changed
}else{clust2->clust3}

#**CLEANUP**
rm(clust2)
gc()
#confused by these commented out lines
#gridmaps$clust <- clust3$cluster
#write.asciigrid(gridmaps["landform"], paste(spath,"/landform_",Nclust,".tif",sep=''),na.value=-9999)

#make map of clusters 

# new method to deal with NA values 
#index of non NA index
n2=which(is.na(scaleDat_all$aspC)==FALSE)
#make NA vector
vec=rep(NA, dim(scaleDat_all)[1])
#replace values
vec[n2]<-as.factor(clust3$cluster)

#**CLEANUP**
rm(scaleDat_all)
#gc()

#gridmaps$landform <- as.factor(clust3$cluster)
gridmaps$landform <-vec
#writeRaster(raster(gridmaps["landform"]), paste(spath,"/landform_",Nclust,".tif",sep=''),NAflag=-9999,overwrite=T)
rst=raster(gridmaps["landform"])
writeRaster(rst, paste0(gridpath,"/landform.tif"),NAflag=-9999,overwrite=T)
pdf(paste0(gridpath,'/landforms.pdf'))
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

# Add long lat of gridbox for each sample (which are positionless) in order to satisfy toposcale_sw.R (FALSE)-> solarCompute()
e=extent(rst)
lonbox=e@xmin + (e@xmax-e@xmin)/2
latbox=e@ymin + (e@ymax-e@ymin)/2
lsp$lat <-rep(latbox,dim(lsp)[1])
lsp$lon <-rep(lonbox,dim(lsp)[1])

write.csv(round(lsp,2),paste0(gridpath, '/listpoints.txt'), row.names=FALSE)

pdf(paste0(gridpath, '/sampleDistributions.pdf'), width=6, height =12)
par(mfrow=c(3,1))
hist(lsp$ele)
hist(lsp$slp)
hist(lsp$asp)
hist(lsp$members)
dev.off()

#make horizon files MOVED TO SEPERATE SCRISPT
#hor(listPath='.')



#get modal surface type of each sample 1=debris, 2=steep bedrock, 3=vegetation
#zoneStats=getSampleSurface(spath=spath,Nclust=Nclust, predFormat=predFormat)
#write.table(zoneStats, paste(spath,'/landcoverZones.txt',sep=''),sep=',', row.names=F)

print("TOPOSUB COMPLETE!")

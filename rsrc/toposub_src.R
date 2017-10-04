#v3.11 
#2/3/12

#==============================================================================
# INPUT FUNCTIONS
#==============================================================================

#decompose aspect to cos/sine components (accepts in degrees only)
aspect_decomp <- function(asp){
	aspC<-cos((pi/180)*asp)
	aspS<-sin((pi/180)*asp)
	return(list(aspC=aspC,aspS=aspS))
}




sampleRandomGrid<-function(nRand, predNames){
#beg function
require(raster)

#index of random sample = rand_vec
ele<-raster(gridmaps['ele'])
sampleRandom(ele, nRand,cells=T, na.rm=T)->x
x[,1]->rand_vec

#read in rasters/stack
for (pred in predNames){
assign(pred, raster(gridmaps[pred]))
if (pred==predNames[1]){stack(get(pred))->stk}else {stack(stk, get(pred))->stk}
}

#extract indexed values from all layers -> cbind
sample_df=c()
for (i in 1:length(predNames)){
 	extract(stk[[i]], rand_vec)-> sample_vec
	sample_df<-cbind(sample_df, sample_vec)
}

#rectify names and class
colnames(sample_df)<-predNames
as.data.frame(sample_df)->sample_df
#end function
}



#convert NA to numeric
natonum <- function(x,predNames,n){
	
	for (pred in predNames){
		x[pred][is.na(x[pred])]<- n
		#x[is.na(x)]<- n
	}
	return(x)
}



#==============================================================================
# KMEANS CLUSTERING functions
#==============================================================================
#scale and make dataframe 

#@celenius center=true just means remove the mean, and 												scale=TRUE stands for divide by SD; in other words, 												with both options active, you're getting standardized 												variables (with mean 0, unit variance, and values 												expressed in SD units)

simpleScale <- function(data, pnames){
	scaleDat <-data.frame(row=dim(data)[1])
	for (pred in pnames){
		b <- as.vector(assign(paste(pred,'W',sep='') , scale(data[pred],center = TRUE, scale = TRUE)))
		scaleDat <- data.frame(scaleDat, b , check.rows=FALSE)
	}
	
	#remove init column
	scaleDat <- scaleDat[,2:(length(pnames)+1)]
#chnge co names
	colnames(scaleDat)<-pnames
	return(scaleDat)
}


findN<-function(scaleDat, nMax,thresh){
	
	#calc. approx number of cluster - dont need to do for weighted run
#make exp sequence
nseq=c()
for (i in 2:sqrt(nMax)){
i^2->n
nseq=c(nseq,n)
}

	
wss <- (nrow(scaleDat)-1)*sum(apply(scaleDat,2,var))
f<-0	
jpeg(paste(eroot_loc1,'/wss.jpg',sep=''),width=600,height=800)
	#for (i in nseq) {wss[i] <- sum(kmeans(scaleDat, centers=i)$withinss)}
for (i in nseq) {f[i] <- (kmeans(scaleDat, centers=i)$betweenss )/(kmeans(scaleDat, centers=i)$tot.withinss)}
	#na.omit(wss)->wss
#wss[1:length(wss)]->wss
na.omit(f)->f
f[1:length(f)]->f
c(1,nseq)->nseq
	plot(nseq, wss, type="b", xlab="Number of Clusters", ylab="Within groups sum of squares")
	dev.off()
	max(wss)->a
	for (i in nseq){
		
		if(wss[i]/a < thresh){i->Nclust
			print('5% cluster found')
			print(Nclust)
			break}
	}
	return(Nclust)
}


Kmeans <- function(scaleDat,iter.max,centers, nstart){
#kmeans algorithm (Hartingen and Wong)
	clust <- kmeans(scaleDat, iter.max=iter.max,centers=Nclust, nstart=nstart)
#make map of clusters
	#gridmaps$clust <- clust$cluster
	#gridmaps$landform <- as.factor(clust$cluster)
	return(clust)
}


#eliminate small samples from kmeans object
sample_redist<-function(pix,samples,thresh_per, clust_obj){

dist(clust_obj$centers, method='euclidean')->dist_matrix # calculate dists
as.matrix(dist_matrix)->dm

(pix/samples)*thresh_per->samples_dead #  define threshold

rank(clust_obj$size)->rank_size # index
sort(clust_obj$size)->sort_size #sort by size
data.frame(rank_size,sort_size)->v #***double check***
v$rank_size[v$sort_size < samples_dead]->samples_rm_vec # vector of sample index to be removed


for(i in samples_rm_vec){	#loop thru samples_rm
sort(dm[i,], decreasing=T)->sort_dm
sort_dm[1]->a
as.numeric(names(a))->cluster_redist # nearest neighbour cluster to redistribute pixels to 
clust_obj$cluster[clust_obj$cluster==i]<-cluster_redist#remap all pixels to new cluster
}
return(clust_obj)
}



#correct asp
meanAspect <- function(dat,agg){
	class.asp <- aggregate(dat[c("aspC", "aspS")], by=list(agg), FUN="sum")
	aspMean<-atan2(class.asp$aspS, class.asp$aspC)	
	aspMean <- aspMean*(180/pi )
	aspMean<-ifelse(aspMean<0,aspMean+360, aspMean)# correct negative values
	asp <- aspMean
	#asp[is.na(asp)]<- -1
	return(asp)
}


#option - use wss to define approx N (SLOW)

#kmClust<-function(gridmaps,Nclust, nMax=170,thresh=0.05, nstart=5, esPath, WSS=0){

#sample cluster centres	
sampleCentroids <- function(dat,predNames, agg, FUN){
	samp <- aggregate(dat[predNames], by=list(agg), FUN=FUN)
	samp$svf<-round(samp$svf,2) 
	return(samp)
}

#==============================================================================
# Get sample attributes
#==============================================================================

listpointsMake <- function(samp_mean, samp_sum){
	
	#make listpoints	

	mem<-samp_sum[2]/samp_mean[2]
	mem$ele->members
	colnames(samp_mean)[1] <- "id"
	listpoints<-data.frame(members,samp_mean)
	return(listpoints)
}



#horizon source here
hor<-function(listPath){
	#reads listpoints at 'listPath' - writes hor dir and files to listPath

		listpoints<-read.table(paste(listPath,'/listpoints.txt', sep=''), header=T, sep=',')
		ID=listpoints$id
		ID<-formatC(ID,width=4,flag="0")
		
		slp=listpoints$slp
		svf=listpoints$svf
		
		(((acos(sqrt(svf))*180)/pi)*2)-slp ->hor.el
		round(hor.el,2)->>hor.el
		dir.create(paste(listPath,'/hor',sep=''), showWarnings = TRUE, recursive = FALSE)
		n<-1 #initialise ID sequence
		for (hor in hor.el){
			IDn<-ID[n]
			Angle=c(45,135,225,315)
			
			Height=rep(round(hor,2),4)
			
			hor=data.frame(Angle, Height)
			write.table(hor, paste(listPath,'/hor/hor_point',IDn,'.txt',sep=''),sep=',', row.names=FALSE, quote=FALSE)
			
			n<-n+1
		}}

#Compute most common surface type in each sample
getSampleSurface=function(spath,Nclust,predFormat){
require(raster)
lc=raster(paste(spath,'/surface',predFormat,sep=''))
zones=raster(paste(spath,'/landform_',Nclust,predFormat,sep=''))
zoneStats=zonal(lc,zones, modal,na.rm=T)
return(zoneStats)
}



#==============================================================================
# linear model for weights functions
#==============================================================================

#just coefficients
linMod <- function(param,col, predNames, mod='gls', scaleIn=FALSE){
	require(MASS)
	require(relaimpo)
require(nlme)
#calc annual mean per TV
	meanX<-	tapply(param[,col],param$IDpoint, mean)
#read in listpoints
	listpoints<-read.table(paste(esPath, '/listpoints.txt',sep=''), sep=',', header=T)
#loop to create dataframe of TV and predictors
	dat <- data.frame(meanX)
	for (pred in predNames){
		dat <- data.frame(dat, listpoints[pred])
	}

##################################################

#pc.dem <- prcomp(x=listpoints[predNames])
#demdata <- as.data.frame(pc.dem$x)

#	fit <- lm(dat$meanX ~ demdata$PC1+ demdata$PC2 + demdata$PC3)
#	summary(fit) # show results
#	coefficients(fit)->coef
#	round(summary(fit)$r.squared,2)->r2
#	coef[1:length(predNames)+1]->x
#	coeffs<-c(col,x,r2)
############################################################

#scale inputs
if(scaleIn==TRUE) {dat= simpleScale(dat, pnames=c('meanX', predNames)
)}

#select ols or gls
if(mod=='ols'){fit <- lm(dat$meanX ~ dat$ele+ dat$slp+ dat$svf + dat$aspC+ dat$aspS)}else{
fit <- gls(meanX ~  ele  + slp + svf + aspC + aspS, dat=dat)
}


	# !remember order of coeffs is tied to order of header in cryosub_prog [order of predNames]! ==> potential bug - fix
	summary(fit) # show results
	coefficients(fit)->coef
	round(summary(fit)$r.squared,2)->r2
	coef[1:length(predNames)+1]->x
	coeffs<-c(col,x,r2)
	
	return(coeffs)
#return(list(coeffs=coeffs,fit=fit, fit_simp=fit_simp))
}

meanCoeffs <- function(weights, nrth){
	
	ele <- mean(abs(weights$ele))
	slp<- mean(abs(weights$slp))
	svf<- mean(abs(weights$svf))
	aspS<- mean(abs(weights$aspS))
	if(nrth==TRUE){north<- mean(abs(weights$north))}else{aspC<- mean(abs(weights$aspC))}
	if(nrth==TRUE){x<-c(ele,slp,svf,aspS, north)}else{x<-c(ele,slp,svf,aspC,aspS)}
	coeff_vec<- (x/sum(x))
	r2 <- mean(weights$r2)
	x<-c(coeff_vec,r2)

return(x)
}

#==============================================================================
# linear model for weights functions - version 2
#==============================================================================

#just coefficients
linMod2 <- function(meanX, listpoints,col, predNames, svfCompute){
require(MASS)
#require(relaimpo)
require(nlme)

#loop to create dataframe of TV and predictors
	names(meanX)<-'meanX'
	dat <- meanX
	for (pred in predNames){
		dat <- data.frame(dat, listpoints[pred])
	}
if(svfCompute == TRUE)
	{
	fit <- lm(meanX ~  ele  + slp + svf + aspC + aspS, dat=dat) #gls gives no r squared
	}

if(svfCompute == FALSE)
	{
	fit <- lm(meanX ~  ele  + slp + aspC + aspS, dat=dat)
	}
	
	# !remember order of coeffs is tied to order of header in cryosub_prog [order of predNames]! ==> potential bug - fix

	coef<-coefficients(fit)
	r2<-round(summary(fit)$r.squared,2)
	x<-coef[2:length(coef)] #dont understnd why intercept auto dropped? Correct tho.
	coeffs<-c(col,x,r2)
	
	return(coeffs)
#return(list(coeffs=coeffs,fit=fit, fit_simp=fit_simp))
}

meanCoeffs <- function(weights, nrth){
	
	ele <- mean(abs(weights$ele))
	slp<- mean(abs(weights$slp))

	if(svfCompute == TRUE)	{	svf<- mean(abs(weights$svf))	}
	aspS<- mean(abs(weights$aspS))
	aspC<- mean(abs(weights$aspC))
	if(svfCompute == TRUE){x<-c(ele,slp,svf,aspC,aspS)}
	if(svfCompute == FALSE){x<-c(ele,slp,aspC,aspS)}
	coeff_vec<- (x/sum(x))
	r2 <- mean(weights$r2)
	x<-c(coeff_vec,r2)

return(x)
}
#==============================================================================
# weighted KMEANS CLUSTERING - lsm samples
#==============================================================================

informScale <- function(data, pnames,weights){
	scaleDat <-data.frame(row=dim(data)[1])
	for (pred in pnames){
		a <- weights[pred][1,1]
		b <- as.vector(assign(paste(pred,'W',sep='') , data[pred]*a))
		scaleDat <- data.frame(scaleDat, b , check.rows=FALSE)
	}
	
#remove init column
	scaleDat <- scaleDat[,2:(length(pnames)+1)]
	return(scaleDat)
}



extentandcells <- function(rstPath){
#get extent
	raster(rstPath)->x
#get number cells
	ncell(x)->cells
	return(list(cells=cells,x=x))
	
}

#function to get stack rasters
stackRst<-function(path,ngrid, type){
	gridNa<-c()
	for (n in 1:ngrid){
	n=formatC(n,width=2,digits = 0,flag="0", format="f")
		paste(path,n,type,sep="")->gridi
		gridNa<-c(gridNa,gridi)
	}
	gridNa<-as.list(gridNa)
	stk<-stack(gridNa)
	return(stk)
}


fuzzyMember <- function(esPath,ext,cells,predNames,data, samp_mean, samp_sd, Nclust){
#create dir for rasters (fuzzy membership)
	rstdir<-paste(esPath, '/raster_tmp', sep='')
	dir.create(rstdir)
	
	#calc distances/ write rasters for n clusters
	for(c in (1:Nclust)){
		distmaps <- as.list(seq(1:Nclust))
		tmp <- rep(NA, cells)
		distsum <- data.frame(tmp)
		distmaps[[c]] <- data.frame(ele=tmp,slp=tmp, aspC=tmp,aspS=tmp, svf=tmp)
		
		for(j in predNames){
			distmaps[[c]][j] <- (((gridmaps@data[j]-samp_mean[c,j])/samp_sd[c,j])^2)
			#distmaps[[c]][j] <- (((aspC-class.c[c,j])/class.sd[c,j])^2)	
		}
		sqrt(rowSums(distmaps[[c]], na.rm=T, dims=1))->v
		setValues(ext,v)->n
		
		c=formatC(c,width=2,digits = 0,flag="0", format="f")#bug fix
#n2=round(n,3) #reduce size
		writeRaster(n, paste(rstdir,"/tmp_", c,'.tif', sep=""), overwrite=T)
		rm(distmaps)
		rm(distsum)
	}

	rst=stackRst(paste(rstdir,'/tmp_', sep=''),ngrid=Nclust, type='.tif')
	
	for(c in (1:Nclust)){
		tot<- (subset(rst,c)^(-2/(fuzzy.e-1)))
		c=formatC(c,width=2,digits = 0,flag="0", format="f")#bug fix
#tot2=round(tot,3)
		writeRaster(tot,paste(rstdir,"/tot_", c, '.tif',sep=""), overwrite=T)
	}
	
	tot=stackRst(paste(rstdir,'/tot_', sep=''),ngrid=Nclust, type='.tif')
	totsum <- sum(tot)
	
	#calc membership stack
	for(c in (1:Nclust)){
		x <- (subset(rst,c)^(-2/(fuzzy.e-1))/totsum)
		c=formatC(c,width=2,digits = 0,flag="0", format="f")#bug fix
x2=round(x,2)
		writeRaster(x2,paste(rstdir,"/mu_", c, '.tif',sep=""), overwrite=T) #membership rasters
	}

#cleanup
setwd(rstdir)
system('rm raster_tmp*')
system('rm tmp*')
system('rm tot*')
}

###function to get 10 most important clusters

topMembers<-function( esPath=esPath, Nclust=Nclust,nFuzMem){
	
rstdir=	paste(esPath, '/raster_tmp', sep='')
rst=stackRst(paste(rstdir,'/mu_', sep=''),ngrid=Nclust, type='.tif')

#whichmax=function(x){a<-which.max(x);return(a)}
#a=stackApply(rst, indices=rep(1,100),fun=max,na.rm=T)
#which.max2 <- function(x, ...) which.max(x) 
# wsa <- stackApply(rst, rep(1,117), fun=which.max2, na.rm=NULL)

sortStack_index <- function(x,i) {a=order(x,decreasing=T)[i]; return(a) }
sortStack_val <- function(x,i) {a=sort(x,decreasing=T)[i]; return(a) }

#x=c(2,4,6,2,9,1,4,6)
#wsa <- stackApply(rst, rep(1,100), fun=sortStack, i=1)
#wsa <- stackApply(rst, rep(1,100), fun=sortStack, i=1)
rst_array=array(getValues(rst), dim=c(nrow(rst),ncol(rst),nlayers(rst)
))

datvec=c()
for(x in 1:nFuzMem){
v=apply(rst_array, MARGIN=c(1,2),FUN=sortStack_index, i=x)
datvec=c(datvec,v)
}
memberIndex=array(datvec, dim=c(dim(v), nFuzMem))

datvec=c()
for(x in 1:nFuzMem){
v=apply(rst_array, MARGIN=c(1,2),FUN=sortStack_val, i=x)
datvec=c(datvec,v)

}
memberVals=array(datvec, dim=c(dim(v),nFuzMem))

save(memberIndex, paste(esPath,'/memberIndex',sep=''))
save(memberVals, paste(esPath,'/memberVals',sep=''))

#r=raster(memberIndex[,,1])
#r=t(r)
#extent(r)<-extent(wsa)
#r=flip(r, direction='y')
}

#==============================================================================
# time series cut 
#==============================================================================

timeSeriesCut <- function( sim_dat, beg, end){ #rmoved esPath,col,
	
	#Period:
	#beg <- "01/07/2010 00:00:00"
	#end <- "01/07/2011 00:00:00"
	timeRange <-strptime(c(beg, end), format="%d/%m/%Y %H:%M")
	beg <- timeRange[1]
	end <- timeRange[2]
	
#Read data from file and prepare date and temperature arrays:
	inDat  <- sim_dat
	dates  <- strptime(inDat[,1], "%d/%m/%Y %H:%M")
	dims   <- dim(inDat)
	nDep   <- dims[[2]] - 1
	nLin   <- dims[[1]]
	tmps   <- data.matrix(inDat[,2:(nDep+1)])
	tmps   <- data.matrix(inDat)
#Cut dates and temperature series to time range:
	lines   <- ((dates)>=beg) & ((dates)<=end) #set all true within tr
	cut <- tmps[lines]
	dCut    <- dates[lines]
	tmpsCut <- tmps[lines,]
	nlines  <- sum(lines)
	as.data.frame(tmpsCut)->sim_dat_cut
	return(sim_dat_cut)
}
#==============================================================================
# time series aggregation 
#==============================================================================

timeSeries <- function(esPath,col, sim_dat_cut, FUN){
	meanX<-	tapply(sim_dat_cut[,col],sim_dat_cut$IDpoint, FUN)
	write.table(meanX, paste(esPath, '/meanX_', col,'.txt', sep=''), sep=',')
}

timeSeries2 <- function(spath,colP, sim_dat_cut, FUN){
	meanX <- tapply(sim_dat_cut[,colP],sim_dat_cut$IDpoint, FUN)
	write(meanX, paste(spath, '/meanX_', col,'.txt', sep=''), sep=',',append=T)
}

#as timeseries 2 but write file as argument
timeSeries3 <- function(spath,col, sim_dat_cut, FUN){
	meanX<-	tapply(sim_dat_cut[,col],sim_dat_cut$IDpoint, FUN)
	#write(meanX, paste(spath, '/meanX_', col,'.txt', sep=''), sep=',',append=T)
return(meanX)
}












#==============================================================================
# SPATIALISE weighted by 4 NN samples in Nspace - crude first implementation
#==============================================================================
##box8 - neighbours = 2,7,9,14
##spatialise sample 6 box 8

#samp=6
#mbox=8
#nbrs=c(2,9,14,7) #clockwise from north
#predNames<-c('ele', 'slp', 'asp', 'svf')
#wm=0.7 #weight main sample
#wn=0.3 # weight of weighted 4 neighbour samples in nspace

spatialWeight=function(mbox,samp, nbrs, predNames=c('ele', 'slp', 'asp', 'svf'), wm=0.7,wn=0.4){
m=read.table(paste('/home/joel/experiments/alpsSim/box',mbox,'/listpoints.txt',sep=''),  sep=',', header=T)
n1=read.table(paste('/home/joel/experiments/alpsSim/box',nbrs[1],'/listpoints.txt',sep=''),  sep=',', header=T)
n2=read.table(paste('/home/joel/experiments/alpsSim/box',nbrs[2],'/listpoints.txt',sep=''),  sep=',', header=T)
n3=read.table(paste('/home/joel/experiments/alpsSim/box',nbrs[3],'/listpoints.txt',sep=''),  sep=',', header=T)
n4=read.table(paste('/home/joel/experiments/alpsSim/box',nbrs[4],'/listpoints.txt',sep=''),  sep=',', header=T)


#generate unique ids
m$id2=paste('mm',m$id,sep='')
n1$id2=paste('n1',m$id,sep='')
n2$id2=paste('n2',m$id,sep='')
n3$id2=paste('n3',m$id,sep='')
n4$id2=paste('n4',m$id,sep='')

#make single matrix
mat=rbind(m,n1,n2,n3,n4) 
mat2=mat[predNames]

distMat=as.matrix(dist(mat2))

#as m is first in rbind -> samp(m) id = samp(distmatrix) id
distVecSamp=distMat[,samp]


#rankSize=rank(distVecSamp) # index
sortSize=sort(distVecSamp)
totalDist=sortSize[2]+sortSize[3]+sortSize[4]+sortSize[5] # 4 nearest neighbours in nspace. sortSize[1] is sample itself.
w1=sortSize[2]/totalDist
w2=sortSize[3]/totalDist
w3=sortSize[4]/totalDist
w4=sortSize[5]/totalDist

weightVec=round(as.numeric(rev(c((w1),(w2),(w3),(w4)))),3) #invert so closet has most weight)
idVec=rev(as.numeric(c(names(w1),names(w2),names(w3),names(w4)))) #sample ids
id2Vec=mat$id2[idVec]

results=data.frame(weightVec, idVec, id2Vec)

#get data
box=substring(results$id2Vec,2,2)
sample=as.numeric(substring(results$id2Vec,3,))

boxmap=data.frame(c(8,2,9,14,7),c('m',1,2,3,4))
names(boxmap)<-c('box','pos')

#read in main result
datin=read.table(paste('/home/joel/experiments/alpsSim/box',mbox,'/meanX_X100.000000.txt',sep=''),  sep=',', header=F)
datm=datin[samp,]

datvec=c()
for(i in 1:length(box)){
n=boxmap$box[boxmap$pos==box[i]]
datin=read.table(paste('/home/joel/experiments/alpsSim/box',n,'/meanX_X100.000000.txt',sep=''),  sep=',', header=F)
dat=datin[sample[i],]
datvec=c(datvec,dat)
}

neigh=sum(datvec*weightVec)

res=(datm*wm)+(neigh*wn)

return(res)
}


#==============================================================================
# SPATIALISE 
#==============================================================================



spatial<-function(col=col, esPath=esPath, format='.tiff', Nclust=Nclust){
	
	rstdir<-paste(esPath, '/raster_tmp', sep='')
	

	meanX <- read.table(paste(esPath, '/meanX_', col,'.txt', sep=''), sep=',', header=T)
	#stack cluster weight rasters
	
	#brick('netCDF.nc')->rst
	rst=stackRst(paste(rstdir,'/mu_', sep=''),ngrid=Nclust, type='.tif')
	
	for(n in (1:Nclust)){
		x<-subset(rst,n)*meanX[n,]
		n=formatC(n,width=2,digits = 0,flag="0", format="f")#bug fix
		writeRaster(x,paste(rstdir, "/tv_", n, '.tif',sep=""), overwrite=T)
	}
	
	tvRst=stackRst(paste(rstdir,'/tv_', sep=''),ngrid=Nclust, type='.tif')
	fuzRst<-sum(tvRst)

	writeRaster(fuzRst, paste(esPath, '/result/out/fuz_',col, '.tif', sep=''),NAflag=-9999, overwrite=T)
#endScript
}

fuzSpatial<-function(col=col, esPath=esPath, format='.tiff', Nclust=Nclust, mask){
	
	rstdir<-paste(esPath, '/raster_tmp', sep='')
	

	meanX <- read.table(paste(esPath, '/meanX_', col,'.txt', sep=''), sep=',')
	#stack cluster weight rasters
	
	#brick('netCDF.nc')->rst
	rst=stackRst(paste(rstdir,'/mu_', sep=''),ngrid=Nclust, type='.tif')
	
	for(n in (1:Nclust)){
		x<-subset(rst,n)*meanX[n,]
		n=formatC(n,width=2,digits = 0,flag="0", format="f")#bug fix
		writeRaster(x,paste(rstdir, "/tv_", n, format,sep=""), overwrite=T)
	}
	
	tvRst=stack(list.files(path=rstdir,full.names=T, pattern='tv'))
	fuzRst<-sum(tvRst,na.rm=T)
	fuzRstMask=fuzRst*mask
	writeRaster(fuzRstMask, paste(esPath, '/result/out/fuz_',col, format, sep=''),NAflag=-9999, overwrite=T)
	
#endScript
}

### speed up sum(rasterstack) operation by spitting raster into blocks of 10 sum each then sum result of each result.
### only multiples of 10 allowed

fuzSpatial_subsum<-function(col=col, esPath=esPath, format='.tif', Nclust=Nclust, mask){
rstdir<-paste(esPath, '/raster_tmp', sep='')

	meanX <- read.table(paste(esPath, '/meanX_', col,'.txt', sep=''), sep=',')
	#stack cluster weight rasters
	
	#brick('netCDF.nc')->rst
	rst=stackRst(paste(rstdir,'/mu_', sep=''),ngrid=Nclust, type='.tif')
	
	for(n in (1:Nclust)){
		x<-subset(rst,n)*meanX[n,]
		n=formatC(n,width=2,digits = 0,flag="0", format="f")#bug fix
x2=round(x,2)
		writeRaster(x2,paste(rstdir, "/tv_", n, format,sep=""), overwrite=T)
	}

tvRst=stack(list.files(path=rstdir,full.names=T, pattern='tv'))
t1=Sys.time()
ivec=seq(1,Nclust,10)
evec=seq(10,Nclust,10)
if(Nclust==10){evec=10}

for (i in 1:(Nclust/10)){
rst=sum(tvRst[[ivec[i]:evec[i]]])
writeRaster(rst, paste(rstdir,'/fuzblock_',i,format,sep=''), NAflag=-9999, overwrite=T)
print(i)
}
t2=Sys.time()-t1
print(t2)

tvRst=stack(list.files(path=rstdir,full.names=T, pattern='fuzblock'))

fuzRst<-sum(tvRst,na.rm=T) #non lnear relationship time of function: number of rasters, 10 = 38s, 50=6.5min, 100=23.9, 200=?
fuzRstMask=fuzRst*mask
fuzRstMask2=round(fuzRstMask,2)
writeRaster(fuzRstMask2, paste(esPath, '/fuz_',col, format, sep=''),NAflag=-9999, overwrite=T)
	
t2=Sys.time()-t1
print(t2)
#cleanup
setwd(rstdir)
system('rm tv*')
system('rm fuzblock*')
system('rm raster_temp*')
}


crispSpatial_noinform<-function(col,Nclust, esPath, landform){

	dir.create(paste(esPath,'/crispRst_noinform/',sep=''))
		
		
		#raster(paste(esPath,"/landform_",es,"Weights.asc",sep=''))->land
	landform->land
	
	meanX <- read.table(paste(esPath, '/meanX_', col,'.txt', sep=''), sep=',', header=T)
		
	as.vector(meanX$x)->meanX
		length(meanX)->l
		seq(1,l,1)->seq
		as.vector(seq)->seq
		
		data.frame(seq,meanX)->meanXdf
		
		
		subs(land, meanXdf,by=1, which=2)->rst
		
		writeRaster(rst, paste(esPath, '/crispRst_noinform/',col,'_',l,'.asc', sep=''),overwrite=T)
	
}

crispSpatial<-function(col,Nclust, esPath, landform){

		dir.create(paste(esPath,'/crispRst/',sep=''))
		#raster(paste(esPath,"/landform_",es,"Weights.asc",sep=''))->land
		landform->land
		meanX <- read.table(paste(esPath, '/meanX_', col,'.txt', sep=''), sep=',', header=T)
		as.vector(meanX$x)->meanX
		length(meanX)->l
		seq(1,l,1)->seq
		as.vector(seq)->seq
		data.frame(seq,meanX)->meanXdf
		subs(land, meanXdf,by=1, which=2)->rst
		writeRaster(rst, paste(esPath,'//crisp_',col,'_',l,'.tif', sep=''),overwrite=T)
	
}

crispSpatial2<-function(col,Nclust,esPath, landform){

		#dir.create(paste(spath,'/crispRst/',sep=''))
		#raster(paste(esPath,"/landform_",es,"Weights.asc",sep=''))->land
		landform->land
		meanX <- read.table(paste(esPath, '/meanX_', col,'.txt', sep=''), sep=',')
		as.vector(meanX)->meanX
		length(meanX$V1)->l
		seq(1,l,1)->seq
		as.vector(seq)->seq
		data.frame(seq,meanX)->meanXdf
		subs(land, meanXdf,by=1, which=2)->rst
rst=round(rst,2)
		writeRaster(rst, paste(esPath,'/crisp_',col,'_',l,'.tif', sep=''),overwrite=T)
}


#provides 'meanX' as argument / return rst
crispSpatial3<-function(col,Nclust,esPath, landform,meanX){
		meanX<-as.vector(meanX)
		l<-length(meanX$V1)
		s<-seq(1,l,1)
		s<-as.vector(s)
		meanXdf<-data.frame(s,meanX)
		rst<-subs(landform, meanXdf,by=1, which=2)
		rst=round(rst,2)
		return(rst)	
}


plotRst <- function(esPath,rootRst, name, formt='.asc',Nclust){
	
	if (name=='gst')(name <- "X100.000000"  )
	if (name=='swe')(name <- "snow_water_equivalent.mm."  )
	if (name=='swin')(name <-  "SWin.W.m2."      )
	if (name=='tair')(name <-  "Tair.C."       )
	
	if (rootRst=='crisp'){rootRst <- paste(esPath,'/crispRst', sep='')}
	if (rootRst=='fuzzy'){rootRst <- paste(esPath,'/fuzRst',sep='')}
rst<-raster(paste(rootRst,'/',name,'_',Nclust,formt,sep=''))
plot(rst)
}



copyFile <- function(expRoot, masterRoot,filename, minExp, maxExp){
seq(minExp,maxExp,1)->expSeq
expSeq<-formatC(expSeq,width=6,digits = 0,flag="0", format="f")
for(i in expSeq){
	
	file.copy(paste(masterRoot,'/',filename, sep=''), paste(expRoot, i,sep=''), overwrite=TRUE)
	
}
}


#=======================================================================================
#				VALIDATE POINTS
#=======================================================================================

#validate points
#Requirements:
#spath='/home/joel/src/hobbes/results4/b8'
##demLoc='/home/joel/src/hobbes/results/b10/box10/preds/ele.tif'
#dat=read.table('/home/joel/data/PERMOS/sites_completeMeta.txt', sep=',', header=T)
#names(dat)[4]<-'ele'
#names(dat)[7]<-'slp'
#names(dat)[8]<-'asp'
#names(dat)[9]<-'svf'
#dat$aspC<-cos(dat$asp*(pi/180))
#dat$aspS<-sin(dat$asp*(pi/180))
#predNames<-c('ele', 'slp', 'svf', 'aspC', 'aspS')
#Nclust=100
#esPath=spath
#data<-dat
#fuzzy.e=1.4

##read in sample centroid data
#samp_mean <- read.table(paste(spath, '/samp_mean.txt' ,sep=''), sep=',',header=T)
#samp_sd <- read.table(paste(spath, '/samp_sd.txt' ,sep=''), sep=',', header=T)


##================== COMPUTE FUZZY MEMBERSHIP MATRIX [SAMPLES * POINTS] =============================
valPoints <- function(esPath,cells,predNames,data, samp_mean, samp_sd, Nclust,fuzzy.e){

#create dir for rasters (fuzzy membership)
	rstdir<-paste(esPath, '/pointsVal', sep='')
	dir.create(rstdir)
	
initdf=c()
	#calc distances/ write rasters for n clusters
	for(c in (1:Nclust)){
		distmaps <- as.list(seq(1:Nclust))
		tmp <- rep(NA, cells)
		distsum <- data.frame(tmp)
		distmaps[[c]] <- data.frame(ele=tmp,slp=tmp, aspC=tmp,aspS=tmp, svf=tmp)
		
		for(j in predNames){
			distmaps[[c]][j] <- (((data[j]-samp_mean[c,j])/samp_sd[c,j])^2)
			
		}
		sqrt(rowSums(distmaps[[c]], na.rm=T, dims=1))->n#v
		initdf=cbind(initdf,n)
	}

initdf2=c()	
for(c in (1:Nclust)){
		tot<- (initdf[,c]^(-2/(fuzzy.e-1)))
		initdf2=cbind(initdf2,tot)
	}
totsum=rowSums(initdf2)


fuzMemMat=c()
	#calc membership stack
	for(c in (1:Nclust)){
		x <- (initdf[,c]^(-2/(fuzzy.e-1))/totsum)
		fuzMemMat=cbind(fuzMemMat,x)
	}
return(fuzMemMat)
}


#============================= COMPUTE FUZZY RESULT ========================================
 
calcFuzPoint=function(dat,fuzMemMat){
#Calculate fuzzy values based sample results and fuzzy membership:
#dat=read.table('/home/joel/src/hobbes/results/b10/box10/meanX_X100.000000.txt', sep=',', header=F)
fuzRes=colSums(dat*t(fuzMemMat))
return(fuzRes)
}
	
crispSpatialInstant<-function(col,Nclust,esPath, landform){
		#dir.create(paste(spath,'/crispRst/',sep=''))
		#raster(paste(esPath,"/landform_",es,"Weights.asc",sep=''))->land
		land <- landform
		latest <- read.table(paste(esPath, '/latest_', col,'.txt', sep=''), sep=',')
		as.vector(latest)->latest
		length(latest$V1)->l
		seq(1,l,1)->seq
		as.vector(seq)->seq
		data.frame(seq,latest)->latestdf
		subs(land, latestdf,by=1, which=2)->rst
		rst=round(rst,2)
		writeRaster(rst, paste(esPath,'/crispINST_',col,'_','.tif', sep=''),overwrite=T)
		}
		
		
		

sampleResultsNow <- function(gridpath, sampleN, targV, date){		
 

	if(targV == "snow_water_equivalent.mm."){file1 <- "surface.txt"}
	if(targV == "X100.000000"){file1 <- "ground.txt"}



	#gsimindex=formatC(i, width=5,flag='0')
	simindex <- paste0(gridpath, '/S',formatC(sampleN, width=5,flag='0'))

	#read in lsm output
	sim_dat <- read.table(paste(simindex,'/out/',file1,sep=''), sep=',', header=T)

	# Get last data point
	dateIndex = which(sim_dat$Date12.DDMMYYYYhhmm.== date)
	
	# 	
	dat <- sim_dat[dateIndex,targV]
	return(dat)

}



crispSpatialNow<-function(resultsVec, landform){
		require(raster)
		l <- length(resultsVec)
		s <- 1:l
		df <- data.frame(s,resultsVec)
		rst <- subs(landform, df,by=1, which=2)
		rst=round(rst,2)
		return(rst)
		}
		
		
		

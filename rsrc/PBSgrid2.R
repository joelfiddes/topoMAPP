# dependency
source("./rsrc/PBS.R") 
require(raster) 
require(zoo)

args = commandArgs(trailingOnly=TRUE)
wd = args[1]
priorwd = args[2]
grid = as.numeric(args[3])
nens = as.numeric(args[4])
Nclust = as.numeric(args[5])
sdThresh=as.numeric(args[6])
R=as.numeric(args[7])
DSTART = as.numeric(args[8])
DEND = as.numeric(args[9])

# load files
load( paste0(wd,"wmat.rd"))
rstack = brick(paste0(wd,"fsca_crop.tif"))
obsTS = read.csv(paste0(wd,"fsca_dates.csv"))
landform = raster(paste0(priorwd,"/grid",grid,"/landform.tif"))
dem = raster(paste0(priorwd,"/predictors/ele.tif"))
lp= read.csv(paste0(priorwd, "grid",grid,"/listpoints.txt"))

# total number of MODIS pixels
npix = ncell( rstack)

#====================================================================
#	Load ensemble results matrix
#====================================================================
load(paste0(wd, "/ensembRes.rd"))

# convert swe > sdThresh to snowcover = TRUE/1
ensembRes[ ensembRes <= sdThresh ] <- 0
ensembRes[ ensembRes > sdThresh ] <- 1

# compute weighted  fsca by memebership
#https://stackoverflow.com/questions/34520567/r-multiply-second-dimension-of-3d-array-by-a-vector-for-each-of-the-3rd-dimension
Vect = lp$members
varr <- aperm(array(Vect, dim = c(dim(ensembRes)[2], dim(ensembRes)[1], dim(ensembRes)[3])), perm = c(2L, 1L, 3L))
arr <- varr * ensembRes


# compute mean MOD fSCA per sample
HX <- apply(arr, FUN = "sum", MARGIN = c(1,3)) / sum(lp$members)




#===============================================================================
#	mean obs routine based on cloud free
#===============================================================================
obs <- cellStats(rstack, 'mean') /100
nNa=c()
for ( i in 1:358 ) {
x=rstack[[i]]
countNa <-  sum(  getValues(is.na(x))  )/ncell(x) 

nNa = c(nNa, countNa)
}

# find highNA scenes and set to NA
index = which(nNa > 0.1)
obs[index] <- NA
glaciers = min(obs,na.rm=T)

obs = obs - glaciers





#===============================================================================
#	mean obs routine based on sample means
#===============================================================================



#compute mean OBS grid fsca from mean sample fsca first to get around missing data issues

# compute pixel map
rst = setValues(rstack[[1]], 1:ncell(rstack))

# dissagrgate modis pixels to finegrid
r = landform
s = rst
d=disaggregate(s, fact=c(round(dim(r)[1]/dim(s)[1]),round(dim(r)[2]/dim(s)[2])), method='') #fact equals r/s for cols and rows
e=resample(d, r,  method="ngb")

# map modis pixel IDS to sample IDS on finegrid
ensem.vec = as.vector(e)
samp.vec = as.vector(r)

# list modis pixels represented in each sample - they should all have similar values
mylist=list()
for( i in 1:Nclust)
	{

	# find index of all samp i pixels
	samp.ind <- which (samp.vec==i)

	# find correspondiong MODIS pixels
	mylist[[i]] <- na.omit(unique(ensem.vec[samp.ind]))

	}

# comput mean obs fsca per sample
fsca.list=list()
sdvec=c()
for( i in 1:Nclust)
	{
	fsca.list[[i]] <- apply(rstack[mylist[[i]]], FUN = "mean", MARGIN=2, na.rm=TRUE)
	 #plot(apply(rstack[mylist[[i]]], FUN = "mean", MARGIN=2, na.rm=TRUE), type='l', main= i)
	sdvec=c(sdvec,mean(apply(rstack[mylist[[i]]], FUN = "sd", MARGIN=2, na.rm=TRUE),na.rm=T))
	}
	
	# list to matrix
	mat <- matrix(unlist(fsca.list), ncol = Nclust, byrow = FALSE)
	
	# weight by memebership
	output <- (mat * lp$members)
	
	# get grid mean
	meanOBS <- apply(output, FUN="sum", MARGIN=1, na.rm=T)/sum(lp$members)
	
	# fill gaps
	OBS <- na.approx(meanOBS)/100
	

	
#===============================================================================
#		PARTICLE FILTER
#===============================================================================	

obsind = which (!is.na(obs))
obsind <- obsind[obsind > DSTART & obsind < DEND]
naind = which (is.na(obs))	

weight = PBS(HX[obsind,], OBS[obsind], R)
	
	
#===============================================================================
#		PLOTTING
#===============================================================================
OBS2PLOT <-OBS
OBS2PLOT[naind]<-NA
prior =HX
weight = as.vector(weight)
ndays = length(obs)

# ======================= posterior = ==========================================

# median
med.post = c()
for ( days in 1:ndays){

mu = prior[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5)
med.post = c(med.post, med$y)
}

# low
low.post = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.05)
low.post = c(low.post, med$y)
}

# high
high.post = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.95)
high.post = c(high.post, med$y)
}



# ======================= prior = ==========================================

# median
med.pri = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = rep((1/nens),nens)
wfill <- w

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5)
med.pri = c(med.pri, med$y)
}

# low
low.pri = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = rep((1/nens),nens)
wfill <- w

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.05)
low.pri = c(low.pri, med$y)
}

# high
high.pri = c()
for ( days in 1: ndays){

mu = prior[ days, ]
w = rep((1/nens),nens)
wfill <- w

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.95)
high.pri = c(high.pri, med$y)
}


pdf(paste0(wd,"/fSCA_grid.pdf"))
plot(high.pri, col='red', type='l', main=i)
lines(low.pri, col='red')
lines(med.pri, col='red', lwd=3)
lines(high.post, col='blue')
lines(low.post, col='blue')
lines(med.post, col='blue', lwd=3)

# posterior blue
y = c(low.post ,rev(high.post))
x = c(1:length(low.post), rev(1:length(high.post)) )
polygon (x,y, col=rgb(0, 0, 1,0.5))

# prior red
y = c(low.pri ,rev(high.pri))
x = c(1:length(low.pri), rev(1:length(high.pri)) )
polygon (x,y, col=rgb(1, 0, 0,0.5))
lines(high.pri, col='red')
lines(low.pri, col='red')
lines(med.pri, col='red', lwd=3)
lines(high.post, col='blue')
lines(low.post, col='blue')
lines(med.post, col='blue', lwd=3)
points(OBS2PLOT, col='green', lwd=4)
legend("topright", c("prior", "posterior") , col=c("red", "blue"), lty=1)
abline(v=DSTART)
abline(v=DEND)
dev.off()



# # spatialise median prior and posterior at clear sky days in MODIS

# #183 193 224 287


# days = 183

# mu = prior[ days, ]
# w = weight
# wfill <- weight
# id<-1:50
# df = data.frame(mu, wfill, id )
# dfOrder =  df[ with(df, order(mu)), ]
# med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5)

# # returns id of median ensemble
# id.med = approx( cumsum(dfOrder$wfill),dfOrder$id , xout=0.5, method="constant", f=0) # could also be 1
# which.max(weight)


# compute PBS at grid level

args = commandArgs(trailingOnly=TRUE)


sdThresh=13

# ======== code ===================
# env
wd = "/home/joel/sim/ensembler_scale_sml/" #"/home/joel/sim/ensembler3/" #"/home/joel/sim/ensembler_scale_sml/" #"/home/joel/sim/ensembler_testRadflux/" #
priorwd = "/home/joel/sim/scale_test_sml/" #"/home/joel/sim/da_test2/"  #"/home/joel/sim/scale_test_sml/" #"/home/joel/sim/test_radflux/" #
grid=9 #2


# variables

# number of ensembles
nens <- 50 #50 #50

# R value for PBS algorithm
R <- 0.016

# number of tsub clusters
Nclust <- 150

# threshold for converting swe --> sca
#sdThresh <- 13

# cores used in parallel jobs
cores=6 # take this arg from config


# dependency
source("./rsrc/PBS.R") 
require(foreach)
require(doParallel)
require(raster) 
require(zoo)

# readin
dem = raster(paste0(priorwd,"/predictors/ele.tif"))
landform = raster(paste0(wd,"ensemble0/grid",grid,"/landform.tif"))
rstack = brick(paste0(priorwd,"fsca_stack.tif"))
obsTS = read.csv(paste0(priorwd,"fsca_dates.csv"))
lp= read.csv(paste0(priorwd, "grid",grid,"/listpoints.txt"))

# crop rstack
rstack = crop(rstack, landform)

# total number of MODIS pixels
npix = ncell( rstack)


#===============================================================================
#	Construct results matrix
#===============================================================================

# retrieve results matrix: ensemble members * samples * timestampsd=strptime(obsTS$x, format='%Y-%m-%d')
d=strptime(obsTS$x, format='%Y-%m-%d')
d2=format(d, '%d/%m/%Y %H:%M')

dat = read.table(paste0(wd,"ensemble0/grid",grid,"/S00001/out/surface.txt"), sep=',', header=T)

# Extract timestamp corresponding to observation
obsIndex = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#convert obsTS to geotop time get index of results that fit obsTS
rstStack=stack()
for (i in 1: nens){ #python index

		resMat=c()
		for (j in 1: Nclust){ 
				simindex=paste0('S',formatC(j, width=5,flag='0'))
				dat = read.table(paste0(wd,"ensemble",i-1,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
				
				resMat = cbind(resMat,dat$snow_water_equivalent.mm.[obsIndex])
				rst=raster(resMat)
				}
				
	rstStack=stack(rstStack, rst)
	myarray = as.array(rstStack)
		}

# convert swe > sdThresh to snowcover = TRUE/1
myarray[ myarray <= sdThresh ] <- 0
myarray[ myarray > sdThresh ] <- 1

# compute weighted  fsca by memebership
#https://stackoverflow.com/questions/34520567/r-multiply-second-dimension-of-3d-array-by-a-vector-for-each-of-the-3rd-dimension
Vect = lp$members
varr <- aperm(array(Vect, dim = c(dim(myarray)[2], dim(myarray)[1], dim(myarray)[3])), perm = c(2L, 1L, 3L))
arr <- varr * myarray


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
r= 0.016
START = 0
END = 350

obsind = which (!is.na(obs))
obsind <- obsind[obsind > START & obsind < END]

naind = which (is.na(obs))	

	weight = PBS(HX[obsind,], OBS[obsind], r)
	
	
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
abline(v=START)
abline(v=END)
#dev.off()



# spatialise median prior and posterior at clear sky days in MODIS

#183 193 224 287


days = 183

mu = prior[ days, ]
w = weight
wfill <- weight
id<-1:50
df = data.frame(mu, wfill, id )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5)

# returns id of median ensemble
id.med = approx( cumsum(dfOrder$wfill),dfOrder$id , xout=0.5, method="constant", f=0) # could also be 1
which.max(weight)


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
#load( paste0(wd,"wmat_",grid,".rd"))
rstack = brick(paste0(priorwd,"fsca_stack.tif"))
obsTS = read.csv(paste0(priorwd,"fsca_dates.csv"))
landform = raster(paste0(priorwd,"/grid",grid,"/landform.tif"))
dem = raster(paste0(priorwd,"/predictors/ele.tif"))
lp= read.csv(paste0(priorwd, "grid",grid,"/listpoints.txt"))

# total number of MODIS pixels
npix = ncell( rstack)
rstack = crop(rstack, landform)
#====================================================================
#	Load ensemble results matrix
#====================================================================
load(paste0(wd, "/ensembRes_",grid,".rd"))

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

# OR:
obs <- cellStats(rstack, 'mean') /100
cloudinessMOD = cellStats(is.na(rstack),'sum') /ncell(rstack) 
cloudfreeMOD= which(cloudinessMOD < 0.1)
cloudMOD= which(cloudinessMOD > 0.1)



	

	
#===============================================================================
#		PARTICLE FILTER
#===============================================================================	

obsind = cloudfreeMOD
obsind <- obsind[obsind > DSTART & obsind < DEND]	

weight = PBS(HX[obsind,], obs[obsind], R)
	
	
#===============================================================================
#		PLOTTING
#===============================================================================
#OBS2PLOT <-OBS
#OBS2PLOT[naind]<-NA
OBS2PLOT = obs
OBS2PLOT[cloudMOD] <- NA
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


#pdf(paste0(wd,"/fSCA_grid.pdf"))
plot(high.pri, col='red', type='l', main=i,  xlim=c(150,ndays))
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
#abline(v=DSTART)
#abline(v=DEND)
#dev.off()

ln = list.files("/home/joel/sim/landsatVal/QA/", pattern="*BQA.TIFsca.tif$")
	jdates= as.numeric(substring(strsplit(strsplit(ln, "/")[[1]][8], "_")[[1]][1], 10,16) )
	year= substring(jdates, 1,4)
	doy = substring(jdates, 5,8)
	date= as.numeric(format(as.Date(as.numeric(doy), origin = paste0(year,"-01-01")), format="%Y%m%d"))
as.numeric(doy) +122

ln = list.files("/home/joel/sim/landsatVal/QA/", pattern="*BQA.TIFsca.tif$", full.name=T)
fsca.vec=c()
for( i in ln[1:4]){
lsat=raster(i)
landform.utm=projectRaster(from=landform, crs=crs(lsat))
lsat.crop = crop(lsat, landform.utm, snap="out")
lsat.wgs=projectRaster(from=lsat.crop, crs=crs(landform), method="ngb")
lsat.crop = crop(lsat.wgs, landform)
fsca = cellStats(lsat.crop, "sum")/ncell(lsat.crop)
fsca.vec=c(fsca.vec,fsca)
}

doy = c(200, 248, 264, 296)

points(doy, fsca.vec,cex=4, col="orange")


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


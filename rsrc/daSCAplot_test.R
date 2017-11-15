require(raster)


sca_wd = "/home/joel/sim/MODIS_ALPS_DA"# contains all the modis data
wd = "/home/joel/sim/wfj_interim_ensemble_v1/"
priorwd = "/home/joel/sim/wfj_interim/"
grid = 1
nens = 50
valshp="/home/joel/data/GCOS/metadata_easy.shp"


#readin
shp=shapefile(valshp)
rstack = brick(paste0(wd,"fsca_crop.tif"))
landform = raster(paste0(priorwd,"/grid",grid,"/landform.tif"))
load( paste0(wd,"/HX.rd"))
load( paste0(wd,"/wmat.rd"))

# settings
ndays=nlayers(rstack)
pix = 1:ncell(rstack) #c(1883, 402,1428, 8014, 1153,1165,1196, 1029)


# get high pixels subset
# dem = raster(paste0(priorwd,"/predictors/ele.tif"))
# elegrid = crop(dem, landform)
# r = aggregate(elegrid,res(rstack)/res(elegrid) )
# rstack_ele <- resample(r , rstack)
# pix = which(getValues(rstack_ele) >2000)
# pix<-pix[50:length(pix)]
#pix=1:20000

# which pixels are our val points?

#pixIDS = extract(rstack[[1]],shp, cellnumbers=T)
#pix=na.omit(pixIDS[,1])

#i= 1428#402#1883 #402, 1428, 8014

#====================================================================
#	PLOT
#====================================================================

#pdf(paste0(wd,"/fSCA.pdf"), height=8, width=5)
rmsvec=c()

plotdim = ceiling(sqrt(length(pix)))
par(mfrow=c(plotdim,plotdim))
par(mfrow=c(3,1))
for( i in pix){
#for( i in 1000:20000){

# get timeseries of obs
pixTS = extract( rstack , 1:ncell(rstack) )
obs = pixTS[i,] /100

# prior
HXvec = HX[i, ]
prior =matrix(HXvec , nrow=ndays, ncol=nens)

# posterior
weight = wmat[i,]










	
	# ===== get melt period / obs index used for computing PBS =====
	vec=pixTS[i,]
	rvec=rev(vec)
	lastdata = which(rvec>0)[1] # last non-zero value
	lastdataindex = length(vec) - lastdata+1
	firstnodata = lastdataindex+1
	lastdateover95 = length(vec) - which (rvec >(max(rvec, na.rm=TRUE)*0.95))[1] # last date over 95% of max value accounts for max below 100%
	start=lastdateover95 
	end=firstnodata
	
	if(!is.na(start) & !is.na(end) & start >= end){
	start=DSTART#lastdateover95 
	end=DEND#firstnodata
	}
	
	if(is.na(start)){
	start=DSTART#lastdateover95 
	}
	
	if(is.na(end)){
	end=DEND#firstnodata
	}	
	
	# identify missing dates and reset start end index
	obsind = which(!is.na(obs)==TRUE)
	
	# cut to start end points (melt season )
	obsind <- obsind[obsind >= start & obsind <= end]
	
















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

plot(high.pri, col='red', type='l', main=i, xlim=c(1,ndays))
lines(low.pri, col='red')
lines(med.pri, col='red', lwd=3)
lines(high.post, col='blue')
lines(low.post, col='blue')
lines(med.post, col='blue', lwd=3)
points(obs, col='green', lwd=4)

# plot only obs used in DA
points(obsind , obs[obsind], col='red', lwd=4)

y = c(low.post ,rev(high.post))
x = c(1:length(low.post), rev(1:length(high.post)) )
polygon (x,y, col=rgb(0, 0, 1,0.5))

y = c(low.pri ,rev(high.pri))
x = c(1:length(low.pri), rev(1:length(high.pri)) )
polygon (x,y, col=rgb(1, 0, 0,0.5))

rmse <- function(error)
{
    sqrt(mean(error^2, na.rm=T))
}

rms = rmse(obs-med.post)
rmsvec=c(rmsvec,rms)
}

#dev.off()






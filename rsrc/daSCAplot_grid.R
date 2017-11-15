require(raster)
wd = "/home/joel/sim/ensembler_scale_sml/"
priorwd = "/home/joel/sim/scale_test_sml/"
grid =9
rstack = brick(paste0(priorwd,"fsca_stack.tif"))
landform = raster(paste0(wd,"ensemble0/grid",grid,"/landform.tif"))

# crop rstack to landform as landform represent grid and rstack the domain not necessarily the same
rstack = crop(rstack, landform)

load( paste0(wd,"/main_results/HX.rd"))
HX <- wmat
load( paste0(wd,"/main_results/wmat_mp.rd"))
wmat <- wmat
ndays=nlayers(rstack)
nens =50
subset=TRUE

# which pixels are our val points?
pixIDS = extract(rstack[[1]],shp, cellnumbers=T)
#i= 1428#402#1883 #402, 1428, 8014

#pdf(paste0(wd,"/fSCA_grid.pdf"))

if (subset == TRUE){
# get pix index
dem = raster(paste0(priorwd,"/predictors/ele.tif"))
landform = raster(paste0(wd,"ensemble0/grid",grid,"/landform.tif"))
elegrid = crop(dem, landform)
r = aggregate(elegrid,res(rstack)/res(elegrid) )
rstack_ele <- resample(r , rstack)

# identify pixels above 2000m do these only
pix = which(getValues(rstack_ele) >2000)

mat = rstack[pix]


obs <- apply(mat, FUN="mean", 2,na.rm=T)/100


}

if (subset == FALSE){
	# get timeseries of obs
	obs <- cellStats(rstack, 'mean') /100
}


nNa=c()
for ( i in 1:ndays ) {
x=rstack[[i]]
#countNa <-  sum(  getValues(is.na(x))  )/ncell(x) 
countNa <-  length(  which(is.na(x[pix]))  ) / length(pix)
nNa = c(nNa, countNa)
}

# find highNA scenes and set to NA
index = which(nNa > 0.1)
obs[index] <- NA
glaciers = min(obs,na.rm=T)

obs = obs - glaciers

# prior
x = apply(HX[pix,], FUN = 'mean', 2)
prior =matrix(x , nrow=ndays, ncol=nens)

# posterior
weight = apply(wmat[pix,], FUN = 'mean', 2)





# ======================= posterior = ==========================================

# median
med.post = c()
for ( days in 1:ndays){

mu = prior[ days, ]
w = weight
wfill <- weight

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
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
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
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
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
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
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
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
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
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
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
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
points(obs, col='green', lwd=4)
legend("topright", c("prior", "posterior") , col=c("red", "blue"), lty=1)


#dev.off()





require(raster)
wd = "/home/joel/sim/ensembler_scale_sml/"
priorwd = "/home/joel/sim/scale_test_sml/"
grid =9
rstack = brick(paste0(priorwd,"fsca_stack.tif"))
landform = raster(paste0(wd,"ensemble0/grid",grid,"/landform.tif"))

# crop rstack to landform as landform represent grid and rstack the domain not necessarily the same
rstack = crop(rstack, landform)
shp=shapefile("/home/joel/data/GCOS/metadata_easy.shp")

  
# [1,] NA     "1MR"
# [2,] NA     "2AN"
# [3,] NA     "2TR"
# [4,] NA     "4UL"
# [5,] NA     "4ZE"
# [6,] "1883" "5DF"
# [7,] "402"  "5KK"
# [8,] "1428" "5WJ"
# [9,] NA     "6SB"
#[10,] NA     "7ST"
#[11,] "8014" "7ZU"



load( paste0(wd,"/main_results/HX.rd"))
HX <- HX
load( paste0(wd,"/main_results/wmat_mp.rd"))
wmat <- wmat
ndays=358
nens =50
pix = c(1883, 402,1428, 8014, 1153,1165,1196, 1029)
myplot = TRUE


# get high pixels
dem = raster(paste0(priorwd,"/predictors/ele.tif"))
elegrid = crop(dem, landform)
r = aggregate(elegrid,res(rstack)/res(elegrid) )
rstack_ele <- resample(r , rstack)
pix = which(getValues(rstack_ele) >2000)

pix<-pix[50:length(pix)]
#pix=1:20000

# which pixels are our val points?
pixIDS = extract(rstack[[1]],shp, cellnumbers=T)
#i= 1428#402#1883 #402, 1428, 8014

if(myplot == TRUE){
#pdf(paste0(wd,"/fSCA.pdf"))
}
rmsvec=c()
par(mfrow=c(4,2))
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




# ======================= posterior = ==========================================

# median
med.post = c()
for ( days in 1:ndays){

mu = prior[ days, ]
w = weight

# fill missing ensemble weights with 0
#index = as.numeric(names(mylist[[ sample ]]))
#df=data.frame(index,w)
#df.new = data.frame(index = 1:nens)
#df.fill = merge(df.new,df, all.x = TRUE)
#wfill=df.fill$Freq
#wfill[which(is.na(wfill))]<-0
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

# fill missing ensemble weights with 0
#index = as.numeric(names(mylist[[ sample ]]))
#df=data.frame(index,w)
#df.new = data.frame(index = 1:nens)
#df.fill = merge(df.new,df, all.x = TRUE)
#wfill=df.fill$Freq
#wfill[which(is.na(wfill))]<-0
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

# fill missing ensemble weights with 0
#index = as.numeric(names(mylist[[ sample ]]))
#df=data.frame(index,w)
#df.new = data.frame(index = 1:nens)
#df.fill = merge(df.new,df, all.x = TRUE)
#wfill=df.fill$Freq
#wfill[which(is.na(wfill))]<-0
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

# fill missing ensemble weights with 0
#index = as.numeric(names(mylist[[ sample ]]))
#df=data.frame(index,w)
#df.new = data.frame(index = 1:nens)
#df.fill = merge(df.new,df, all.x = TRUE)
#wfill=df.fill$Freq
#wfill[which(is.na(wfill))]<-0
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

# fill missing ensemble weights with 0
#index = as.numeric(names(mylist[[ sample ]]))
#df=data.frame(index,w)
#df.new = data.frame(index = 1:nens)
#df.fill = merge(df.new,df, all.x = TRUE)
#wfill=df.fill$Freq
#wfill[which(is.na(wfill))]<-0
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

# fill missing ensemble weights with 0
#index = as.numeric(names(mylist[[ sample ]]))
#df=data.frame(index,w)
#df.new = data.frame(index = 1:nens)
#df.fill = merge(df.new,df, all.x = TRUE)
#wfill=df.fill$Freq
#wfill[which(is.na(wfill))]<-0
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

if(myplot == TRUE){
#ev.off()
}




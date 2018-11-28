# transient routine
sca_wd = "/home/joel/sim/MODIS_ALPS_DA"# contains all the modis data
wd = "/home/joel/sim/wfj_interim2_ensemble_v1/"
priorwd = "/home/joel/sim/wfj_interim2/"
grid = 1
nens = 50
Nclust=150
valshp = "/home/joel/data/GCOS/metadata_easy.shp"

require(raster)
require(plotKML)
require(scales)
library(viridis)
library(abind)

shp=shapefile(valshp)
rstack = brick(paste0(wd,"fsca_crop.tif"))
landform = raster(paste0(priorwd,"/grid",grid,"/landform.tif"))
dem = paste0("/home/joel/sim/wfj_interim2/predictors/ele.tif")
load( paste0(wd,"/HX.rd"))
load( paste0(wd,"/wmat.rd"))
load( paste0(wd,"/sampleWeights.rd"))
load( paste0(wd,"/ensembRes.rd"))
ndays=nlayers(rstack)

ndays = length(ensembRes[ , 1, 1])


trans=list()
for (sample in 1:Nclust){
print(sample)
# POSTERIOR

#median
median.post = c()
for ( i in 1: ndays){

mu = ensembRes[ i, sample, ]
w = sampleWeights[[ sample ]]

# fill missing ensemble weights with 0
index = as.numeric(names(sampleWeights[[ sample ]]))
df=data.frame(index,w)
df.new = data.frame(index = 1:nens)
df.fill = merge(df.new,df, all.x = TRUE)
wfill=df.fill$Freq
wfill[which(is.na(wfill))]<-0


df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5)
median.post = c(median.post, med$y)
}

##==========================Compute quantiles=====================================

low.post = c()
for ( i in 1: ndays){

mu = ensembRes[ i, sample, ]
w = sampleWeights[[ sample ]]

# fill missing ensemble weights with 0
index = as.numeric(names(sampleWeights[[ sample ]]))
df=data.frame(index,w)
df.new = data.frame(index = 1:nens)
df.fill = merge(df.new,df, all.x = TRUE)
wfill=df.fill$Freq
wfill[which(is.na(wfill))]<-0


df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.05)
low.post = c(low.post, med$y)
}


high.post = c()
for ( i in 1: ndays){

mu = ensembRes[ i, sample, ]
w = sampleWeights[[ sample ]]

# fill missing ensemble weights with 0
index = as.numeric(names(sampleWeights[[ sample ]]))
df=data.frame(index,w)
df.new = data.frame(index = 1:nens)
df.fill = merge(df.new,df, all.x = TRUE)
wfill=df.fill$Freq
wfill[which(is.na(wfill))]<-0


df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.95)
high.post = c(high.post, med$y)
}


# PRIOR

# MEDIAN
median.prior = c()
for ( i in 1: ndays){

mu = ensembRes[ i, sample, ]
w = rep((1/nens),nens)

df = data.frame(mu, w )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$w),dfOrder$mu , xout=0.5)
median.prior = c(median.prior, med$y)
}


# 5%
low.prior = c()
for ( i in 1: ndays){

mu = ensembRes[ i, sample, ]
w = rep((1/nens),nens)

df = data.frame(mu, w )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$w),dfOrder$mu , xout=0.05)
low.prior = c(low.prior, med$y)
}

# 95%
high.prior = c()
for ( i in 1: ndays){

mu = ensembRes[ i, sample, ]
w = rep((1/nens),nens)

df = data.frame(mu, w )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$w),dfOrder$mu , xout=0.95)
high.prior = c(high.prior, med$y)
}
df = data.frame(median.prior, low.prior, high.prior, median.post, low.post, high.post)
trans[[sample]] <- df
}


transArray <- do.call(abind, c(trans, along = 3))

#plot median
#ad plot 95-90% as opacity on a pixel basis
 s= 1:Nclust

pb <- txtProgressBar(min = 0, max = ndays-150, style = 3)



for ( days in 1:ndays){
print(days)
		meanX <- transArray[days,4,]
		meanXdf <- data.frame(s,meanX)
		med <- subs(landform, meanXdf,by=1, which=2)

		meanX <- transArray[days,5,]
		meanXdf <- data.frame(s,meanX)
		low <- subs(landform, meanXdf,by=1, which=2)
		
		meanX <- transArray[days,6,]
		meanXdf <- data.frame(s,meanX)
		high <- subs(landform, meanXdf,by=1, which=2)		
		
		range =high-low
		
		
		#writeRaster(rst,  paste0(wd,"/raster/med.post",days,".tif"))

		


w1 = alpha("white", alpha = 0)
w2 = alpha("white", alpha = 0.1)
w3 = alpha("white", alpha = 0.3)
w4 = alpha("white", alpha = 0.5)
w5 = alpha("white", alpha = 0.7)
w6 = alpha("white", alpha = 0.7)
w7 = alpha("white", alpha = 0.7)
w8 = alpha("white", alpha = 0.7)
w9 = alpha("white", alpha = 0.7)
w10 = alpha("white", alpha = 0.7)
w11 = alpha("white", alpha = 0.7)

#med[med < 5] <- NA
#rbrick = stack(list.files(path = wd, pattern = ("med.post"), full.names=T))
#animate(rbrick, pause=0.25, maxpixels=50000)
jpeg(paste0(wd,"/raster/medpost",days,".jpg"),width=800, height =400 )
breakpoints <- seq(0, 2000,200 )
colors <-c(w1,w2,w3,w4,w5,w6,w7,w8,w9,w10)
#colors <- rep(w10,10)
par(mfrow=c(1,2))
plot(med, col = rev(inferno(256)), axes=FALSE, box=FALSE)
plot(range,col=rev(inferno(256)),axes=FALSE, box=FALSE) #breaks=breakpoints,
dev.off()
		setTxtProgressBar(pb, days)
		}
		close(pb)
		
		
rstack = stack(list.files(path = paste0(wd,"/raster/"), pattern = ("med.post"), full.names=T)[190:210])		
rbrick <- brick(rstack)
kml_layer.RasterBrick(rbrick)	



> kml_open("swe.kml")
KML file opened for writing...
> kml_layer(rst, colour_scale = rev(inferno(256)))

> kml_close("swe.kml")

			

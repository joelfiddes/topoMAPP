require(raster)
priorwd=  "/home/joel/mnt/myserver/nas/sim/SIMS_JAN18/gcos_cor/"
wd = "/home/joel/mnt/myserver/nas/sim/SIMS_JAN18/gcos_cor_ensemble/"
grid=1
year=0
day=200
lsat = raster("/home/joel/sim/landsatVal/QA/LC81940272016078LGN00_BQA.TIFsca.tif")
# readin
landform = raster(paste0(priorwd,"/grid",grid,"/landform.tif"))
rstack = brick(paste0(wd, "//fsca_crop",grid,year,".tif"))

#Load ensemble results matrix
load(paste0(wd, "//ensembRes_",grid,".rd"))

# load pixel weights
load(paste0(wd,"//wmat_",grid,year,".rd"))
load(paste0(wd,"//HX_",grid,year,".rd"))

# subset temporally
#startda <- substr(startdaLong, 1, 10)# remove HH:mm part of timestamp (yyyy-mm-dd HH:mm)-> datestamp (yyy-mm-dd)
#endda <- substr(enddaLong, 1, 10)
#totalTS <- seq(as.Date(startSim), as.Date(endSim), 1)
#start.index <- which(totalTS == startda)
#end.index <- which(totalTS == endda)
#ensembRes <- ensembRes[start.index:end.index, , ]

wpix <- wmat

# compute ensemble index of max weight per pixel
ID.max.weight = apply(wmat, 1, which.max) 
#max.weight = apply(wmat, 1, max) 

# make raster container
rst <- rstack[[1]]

# fill with values ensemble ID
rst = setValues(rst, as.numeric(ID.max.weight))


r = landform
s = rst
d=disaggregate(s, fact=c(round(dim(r)[1]/dim(s)[1]),round(dim(r)[2]/dim(s)[2])), method='') #fact equals r/s for cols and rows
e=resample(d, r,  method="ngb")


ensem.vec = as.vector(e)
samp.vec = as.vector(r)
  
df =cbind(ensem.vec, samp.vec)
df.u = unique(df)
res.vec=(rep(NA, length(ensem.vec)))
 
for (i in 1:length(df.u[,1]) ){
 print(i)
 index = which(df[,1]==df.u[i,1] & df[,2]==df.u[i,2])
 res.vec[index]<- ensembRes[day,df.u[i,2], df.u[i,1]]
 }
 
 
# slow pixel
# resvec=c()
# for (i in 1:length(samp.vec)){
# ensemb = ensem.vec[i]
# val = ensembRes[150,samp.vec[i], ensemb]
# resvec=c(resvec, val)
#}


mat = raster(matrix(res.vec, nrow=nrow(landform), ncol=ncol(landform), byrow=T))
extent(mat)<- extent(landform)
crs(mat)<-crs(landform)




# landsat VAL
landform.utm=projectRaster(from=landform, crs=crs(lsat))
lsat.crop = crop(lsat, landform.utm, snap="out")
lsat.wgs=projectRaster(from=lsat.crop, crs=crs(landform), method="ngb")
lsat.crop = crop(lsat.wgs, landform)


# spatialise function
crispSpatialNow<-function(resultsVec, landform){
		require(raster)
		l <- length(resultsVec)
		s <- 1:l
		df <- data.frame(s,resultsVec)
		rst <- subs(landform, df,by=1, which=2)
		rst=round(rst,2)
		return(rst)
		}
		
#md = apply(ensembRes[day,,], 1, mean)
#ma = apply(ensembRes[,,], 2, mean)
#mdc= crispSpatialNow(md, landform)
#mac=crispSpatialNow(ma, landform)


# open loop
gridpath = paste0(priorwd, "/grid1/")

# function to retrieve results
list2ary = function(input.list){  #input a list of lists
  rows.cols <- dim(input.list[[1]])
  sheets <- length(input.list)
  output.ary <- array(unlist(input.list), dim = c(rows.cols, sheets))
  colnames(output.ary) <- colnames(input.list[[1]])
  row.names(output.ary) <- row.names(input.list[[1]])
  return(output.ary)    # output as a 3-D array
}

sRes.names = list.files(gridpath, pattern = "surface.txt", recursive=TRUE, full.name=TRUE)
sRes.list = lapply(sRes.names, FUN=read.csv,  sep=',', header=T)
sRes <- list2ary(sRes.list)  # convert to array
md2=sRes[day,"snow_water_equivalent.mm.",]
mdc2= crispSpatialNow(md2, landform)


library(viridis)


pal <- rev(inferno(10))


pdf("/home/joel/sim/DA_2016078.pdf")
par(mfrow=c(2,3))

mat[mat==0] <- NA
mdc2[mdc2==0] <- NA

plot(mat, main=paste("DA/ max swe=", cellStats(mat, "max", na.m=T)),  col = pal,zlim=c(0,2000))

plot(density(getValues(mdc2), na.rm=T), lwd=3, col='red', xlim=c(0,2000), main="Density SWE")
lines(density(getValues(mat), na.rm=T), lwd=3, col='blue')
legend("topright", col=c("red", "blue"), legend=c("open-loop", "Post"), lwd=2, lty=1)
plot(mdc2, main=paste("open-loop/ max swe=", cellStats(mdc2, "max", na.m=T)), col = pal, zlim=c(0,2000))
#plot(rstack[[day]])

mat_sca<-mat
mat_sca[mat_sca <= 13] <-0
mat_sca[mat_sca > 13] <-1

mdc_sca<-mdc2
mdc_sca[mdc_sca <= 13] <-0
mdc_sca[mdc_sca > 13] <-1

plot(mat_sca, main="DA")
plot(lsat.crop, main="landsat NDSI")
plot(mdc_sca, main="open-loop")
#plot(rstack[[day-1]])

dev.off()










# generic plot pars
lwd=3
pdf(paste0(wd,"/plots/swe_pix",grid,year,"SPATIAL.pdf"), height=8, width=5)



























## POSTERIOR


ndays = 264
samples=1:150



median.vec = c()
for ( i in samples){

mu = ensembRes[ ndays, i, ]
wfill = wpix[ j, ]
df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5)
median.vec = c(median.vec, med$y)
}

##==========================Compute quantiles=====================================

low.vec = c()
for ( i in samples){

mu = ensembRes[ ndays, i, ]
wfill = wpix[ j, ]

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.05)
low.vec = c(low.vec, med$y)
}


high.vec = c()
for ( i in samples){
mu = ensembRes[ ndays, i, ]
wfill = wpix[ j, ]
df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.95)
high.vec = c(high.vec, med$y)
}


# PRIOR

# MEDIAN
median.prior = c()
for ( i in samples){

mu = ensembRes[ ndays, i, ]
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
for ( i in samples){

mu = ensembRes[ ndays, i, ]
w = rep((1/nens),nens)

df = data.frame(mu, w )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$w),dfOrder$mu , xout=0.05)
low.prior = c(low.prior, med$y)
}

# 95%

high.prior = c()
for ( i in samples){

mu = ensembRes[ ndays, i, ]
w = rep((1/nens),nens)

df = data.frame(mu, w )
dfOrder =  df[ with(df, order(mu)), ]
med = approx( cumsum(dfOrder$w),dfOrder$mu , xout=0.95)
high.prior = c(high.prior, med$y)
}


#
valdat<- myList[[j]]
# convert obs timestamps
d = strptime(valdat$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M') #geotop format
#d3=format(d, '%Y/%m/%d') # obsvec format

# used to get time index - just use first sim 
dat = read.table(paste0(priorwd,"/grid",grid,"/S00001/out/surface.txt"), sep=',', header=TRUE)

# cut to year
dat =dat[start.index:end.index,]

#index of sim data in obs
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

# index of obs in sim data
simIndexVal = which(d2 %in% dat$Date12.DDMMYYYYhhmm.)

# obs
val = valdat$SWE.mm[simIndexVal]

# modal swe
#swe_modal = swe_mod[,id]

# plot prior,post, obs
# plot prior,post, obs
plot(median.prior, ylim=c(0,1000),col='blue', type='l',lwd=3,xaxt = "n",main=paste0(stat[j], sample)) # prior
for (i in 1:nens){lines(ensembRes[,sample,i], col='grey')}

# 90 percentile and median prior
y = c(low.prior ,rev(high.prior))
x = c(1:length(low.prior), rev(1:length(high.prior)) )
polygon (x,y, col=rgb(1, 0, 0,0.5))

# 90 percentile and median posterioir
y = c(low.vec ,rev(high.vec))
x = c(1:length(low.vec), rev(1:length(high.vec)) )
polygon (x,y, col=rgb(0, 0, 1,0.5))
lines(median.vec, col='blue',lwd=3)
lines(median.prior, col='red',lwd=3)

#obs
points(obsIndexVal,val, lwd=lwd, cex=2, col='black',pch=24) #obs

#modal
#lines(swe_modal, col='green',lwd=3)

axis(side=1,at=1:length(dat$Date12.DDMMYYYYhhmm.) , labels=substr(dat$Date12.DDMMYYYYhhmm.,1,10),tick=FALSE)
legend("topright",c("SWE_prior","SWE_post_median", "SWE_post_mode", "SWE_obs" , "ENSEMBLE"),col= c("red","blue", "green","black", "grey"), lty=c(1,1,1,NA, 1),pch=c(NA,NA,NA, 24,NA),lwd=lwd, cex=0.7)



crispSpatialNow<-function(resultsVec, landform){
		require(raster)
		l <- length(resultsVec)
		s <- 1:l
		df <- data.frame(s,resultsVec)
		rst <- subs(landform, df,by=1, which=2)
		rst=round(rst,2)
		return(rst)
		}
		
		
	prior =	crispSpatialNow(median.prior, landform)
	post = crispSpatialNow(median.vec, landform)
	
par(mfrow=c(1,3))	
plot(prior)
plot(post)

lsat = raster("/home/joel/sim/landsatVal/QA/LC81940272016142LGN00_BQA.TIFsca.tif")
landform.utm=projectRaster(from=landform, crs=crs(lsat))
lsat.crop = crop(lsat, landform.utm, snap="out")
lsat.wgs=projectRaster(from=lsat.crop, crs=crs(landform), method="ngb")
lsat.crop = crop(lsat.wgs, landform)

plot(lsat.crop)

# threshold
sdThresh = 13
prior[prior <= sdThresh] <-NA
prior[prior>sdThresh] <- 1

post[post <= sdThresh] <-NA
post[post>sdThresh] <- 1

par(mfrow=c(1,3))	
plot(prior)
plot(post)
plot(lsat.crop)

lsat.re = resample(lsat.crop, prior, method='ngb')
prior[is.na(prior)]<-0
cor(getValues(prior), getValues(lsat.re))

post[is.na(post)]<-0
cor(getValues(post), getValues(lsat.re))



# plot the curves


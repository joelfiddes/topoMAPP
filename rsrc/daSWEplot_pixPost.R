require(raster)

args = commandArgs(trailingOnly=TRUE)
wd = args[1]
priorwd = args[2]
grid = as.numeric(args[3])
nens = as.numeric(args[4])
valshp=args[5]
year=args[6]

# readin
landform = raster(paste0(priorwd,"/grid",grid,"/landform.tif"))
shp=shapefile(valshp)
rstack = brick(paste0(wd,"fsca_crop",grid,year,".tif"))

#	Load ensemble results matrix
load(paste0(wd, "/ensembRes_",grid,".rd"))

#	Load sample weights
#load(paste0(wd,"/sampleWeights.rd"))

# load pixel weights
load(paste0(wd,"/wmat_",grid,".rd"))

# rmse func
rmse <- function(error)
{
    sqrt(mean(error^2))
}

# read locations on finegrid
samples = na.omit(extract(landform,shp))

posits.fg = intersect(shp,landform)
stat = posits.fg$STAT_AB
Nval = length(stat)
# read in data
myfilenames = paste0("/home/joel/data/GCOS/sp_",stat,".txt")
myList <- lapply(myfilenames, read.csv) 

# pix weights at MODIS
rtest <- rstack[[1]]
values(rtest) <- 1: ncell(rtest)
posits.pix = na.omit(extract(rtest, shp))
#er <- ensembRes[,posits.pix,]
wpix <- wmat[posits.pix,] # pixel weights



#===============================================================================
#			compute MODAL
# #===============================================================================
# Nclust = length(ensembRes[1,,1])

# 	swe_mod=c()
#  	for ( i in posits.fg ){
# 	# vector of ensemble IDs
# 	ids = as.numeric(names(sampleWeights[[i]]))
	
# 	# vector of ensemble weights 
# 	weights = as.numeric((sampleWeights[[i]]))
# 	 #weights[ which.max(weights) ]<-1
# 	# weights[weights<1]<-0
# 	# multiply filtered timeseries for sample 1 and ensembles memebers "ids"

# 	medn <- ids[which.max(weights)]

# 	we <-  ensembRes[,i,medn] 



# 	#if(!is.null(dim(we))){we = rowSums(we)}
# 	swe_mod=cbind(swe_mod, we) # time * samples weighted 
 
#  }
#===============================================================================
#			New plot routine - compute SWE posterior
#===============================================================================

# generic plot pars
lwd=3
pdf(paste0(wd,"/swe_pix.pdf"), height=8, width=5)

par(mfrow=c(ceiling(sqrt(Nval)),ceiling(sqrt(Nval))))
par(mfrow=c(3,1))


for ( j in 1:length(samples) ) {

## POSTERIOR
# sample ID



sample=samples[j]
	


ndays = length(ensembRes[ , 1, 1])

print(sample)
print(posits.pix[j])
median.vec = c()
for ( i in 1: ndays){

mu = ensembRes[ i, sample, ]
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
for ( i in 1: ndays){

mu = ensembRes[ i, sample, ]
wfill = wpix[ j, ]

df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.05)
low.vec = c(low.vec, med$y)
}


high.vec = c()
for ( i in 1: ndays){

mu = ensembRes[ i, sample, ]
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
id=samples[j]

sample= id
ndays = length(ensembRes[ , 1, 1])

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
id=samples[j]

sample= id
ndays = length(ensembRes[ , 1, 1])

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
id=samples[j]

sample= id
ndays = length(ensembRes[ , 1, 1])

high.prior = c()
for ( i in 1: ndays){

mu = ensembRes[ i, sample, ]
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
plot(median.prior, ylim=c(0,1000),col='blue', type='l',lwd=3,xaxt = "n",main=paste0(stat[j])) # prior
for (i in 1:nens){lines(ensembRes[,id,i], col='grey')}

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

}

dev.off()




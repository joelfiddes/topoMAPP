# dependency
library("foreach")
library("doParallel")
require(raster) 

#  ================ GRID 9 =================================
gridN = 9
 if( gridN == 9){
 print (gridN)
#wd = "/home/joel/sim/ensembler3/"
#priorwd = "/home/joel/sim/da_test2/" 
wd = "/home/joel/sim/ensembler_scale_sml/" 
priorwd = "/home/joel/sim/scale_test_sml/"
grid=9
# IO files
plotout=(paste0(wd,"/daplot_median.pdf"))
load( paste0(wd,"wmat_2.rd"))
rstack = rstack_save #brick(paste0(priorwd,"fsca_stack.tif"))
obsTS = read.csv(paste0(priorwd,"fsca_dates.csv"))

# variables
start=180
end=300
# number of ensembles
nens=50

# R value for PBS algorithm
R=0.016

# number of tsub clusters
Nclust=150

# threshold for converting swe --> sca
sdThresh <- 13

# cores used in parallel jobs
cores=4
 }
 #  ================ GRID 5 =================================
 if( gridN == 5){
  print (gridN)
wd = "/home/joel/sim/ensembler3/"
priorwd = "/home/joel/sim/da_test2/" 

grid=1
# IO files
plotout=(paste0(wd,"/daplot_median.pdf"))
load( paste0(wd,"wmat_2.rd"))
rstack = brick(paste0(priorwd,"fsca_stack.tif"))
obsTS = read.csv(paste0(priorwd,"fsca_dates.csv"))

# variables
start=180
end=300

# number of ensembles
nens=100

# R value for PBS algorithm
R=0.016

# number of tsub clusters
Nclust=150

# threshold for converting swe --> sca
sdThresh <- 13

# cores used in parallel jobs
cores=4
 }
# ======== code ===================

# readin
landform = raster(paste0(wd,"ensemble0/grid",grid,"/landform.tif"))

# crop rstack to landform as landform represent grid and rstack the domain not necessarily the same
rstack = crop(rstack, landform)

# total number of MODIS pixels
npix = ncell( rstack)

# compute ensemble index of max weight per pixel
ID.max.weight = apply(wmat, 1, which.max) 
#max.weight = apply(wmat, 1, max) 

# make raster container
rst <- rstack[[1]]

# fill with values ensemble ID
rst = setValues(rst, as.numeric(ID.max.weight))

#===============================================================================
#	Run pixel calcs in vectorised form
#===============================================================================
getmode <- function(v) {
   uniqv <- unique(v)
   uniqv[which.max(tabulate(match(v, uniqv)))]
}

r = landform
s = rst
d=disaggregate(s, fact=c(round(dim(r)[1]/dim(s)[1]),round(dim(r)[2]/dim(s)[2])), method='') #fact equals r/s for cols and rows
e=resample(d, r,  method="ngb")

ensem.vec = as.vector(e)
samp.vec = as.vector(r)

modal_ensembID=c()
mylist=list()
for ( i in 1 : Nclust ){

# get vector of ensembles that exist in each sample
vec = ensem.vec[which(samp.vec==i)]

# get weights of each ensemble
ensemble_weights = table(vec)/length(vec)

#
mylist[[i]] <- ensemble_weights 

# get modal ensemble per sample
meid = getmode(vec)
modal_ensembID=c(modal_ensembID, meid)
}

save(mylist, file = paste0(wd,"mylist.rd"))


#===============================================================================
#			get results matrix
#===============================================================================


rstStack=stack()
for (i in 1: nens){ #python index

	resMat=c()
	for (j in 1: Nclust){ 
		simindex=paste0('S',formatC(j, width=5,flag='0'))
		dat = read.table(paste0(wd,"ensemble",i-1,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
		
		
		resMat = cbind(resMat,dat$snow_water_equivalent.mm.)
		rst=raster(resMat)
	}
rstStack=stack(rstStack, rst)
myarray = as.array(rstStack)
}

# convert swe > sdThresh to snowcover = TRUE/1
# dimension = time * sample * ensemble
# convert swe > sdThresh to snowcover = TRUE/1
#myarray[myarray>sdThresh]<-1

#keep myarray swe
myarray_swe <- myarray

# compute sca results
myarray[myarray<=sdThresh]<-0
myarray[myarray>sdThresh]<-1


#===============================================================================
#			compute weight ensemble per sample - posterior SWE
#===============================================================================
 
# we_mat=c()
# for ( i in 1:Nclust ){
#	# vector of ensemble IDs
#	ids = as.numeric(names(mylist[[i]]))
#	
#	# vector of ensemble weights 
#	weights = as.numeric((mylist[[i]]))
#	 #weights[ which.max(weights) ]<-1
#	# weights[weights<1]<-0
#	# multiply filtered timeseries for sample 1 and ensembles memebers "ids"
#	we <-  myarray_swe[,i,ids] %*%weights
#	#if(!is.null(dim(we))){we = rowSums(we)}
#	we_mat=cbind(we_mat, we) # time * samples weighted 
# 
# }
	

#===============================================================================
#			compute modal swe
#===============================================================================

	we_mat=c()
 	for ( i in 1:Nclust ){
	# vector of ensemble IDs
	ids = as.numeric(names(mylist[[i]]))
	
	# vector of ensemble weights 
	weights = as.numeric((mylist[[i]]))
	 #weights[ which.max(weights) ]<-1
	# weights[weights<1]<-0
	# multiply filtered timeseries for sample 1 and ensembles memebers "ids"

	medn <- ids[which.max(weights)]

	we <-  myarray_swe[,i,medn] 



	#if(!is.null(dim(we))){we = rowSums(we)}
	we_mat=cbind(we_mat, we) # time * samples weighted 
 
 }


#===============================================================================
#			compute weight ensemble per sample - posterior sca
#===============================================================================
 
# we_mat_sca=c()
# for ( i in 1:Nclust ){
#	# vector of ensemble IDs
#	ids = as.numeric(names(mylist[[i]]))
#	
#	# vector of ensemble weights 
#	weights = as.numeric((mylist[[i]]))
#	 
#	
#	# multiply filtered timeseries for sample 1 and ensembles memebers "ids"
#	we <-  myarray[,i,ids] %*%weights
#	#if(!is.null(dim(we))){we = rowSums(we)}
#	we_mat_sca=cbind(we_mat_sca, we) # time * samples weighted 
# 
# }

#===============================================================================
#			compute modal sca
#===============================================================================

	we_mat_sca=c()
 	for ( i in 1:Nclust ){
	# vector of ensemble IDs
	ids = as.numeric(names(mylist[[i]]))
	
	# vector of ensemble weights 
	weights = as.numeric((mylist[[i]]))
	 #weights[ which.max(weights) ]<-1
	# weights[weights<1]<-0
	# multiply filtered timeseries for sample 1 and ensembles memebers "ids"

	medn <- ids[which.max(weights)]

	we <-  myarray[,i,medn] 



	#if(!is.null(dim(we))){we = rowSums(we)}
	we_mat_sca=cbind(we_mat_sca, we) # time * samples weighted 
 
 }
 
#===============================================================================
#	construct sample observed SCA
#===============================================================================
shp=shapefile("/home/joel/data/GCOS/metadata_easy.shp")
pointObs= extract(rstack,shp)

# get generic results set for timestamps vector
dat = read.table(paste0(wd,"ensemble0/grid",grid,"/S00001/out/surface.txt"), sep=',', header=T)
# get obs values
#which(obsTS in )

d = strptime(obsTS$x, format="%Y-%m-%d")
d2=format(d, '%d/%m/%Y %H:%M') #geotop format
#d3=format(d, '%Y/%m/%d') # obsvec format

# GET CORRESPONDING SIM TIMESTAMPS of profile obs 
obsIndex.MOD = which(dat$Date12.DDMMYYYYhhmm. %in% d2)
#===============================================================================
#	EVALUATE
#===============================================================================
# compute rmse ensemble v obs fSCA
rmse <- function(error)
{
    sqrt(mean(error^2))
}

#2AN = pk2 = sample 21
#2TR = pk3 = sample 7
#4UL = pk4 = sample 36

#===============================================================================
#	Grid 5
#===============================================================================
#pkvec=c(2:4)
#tr = read.csv("/home/joel/data/GCOS/sp_2TR.txt")
#ul = read.csv("/home/joel/data/GCOS/sp_4UL.txt")
#an = read.csv("/home/joel/data/GCOS/sp_2AN.txt")

##subset
#tr = tr[539:543,]
#ul = ul[422:427,]
#an = an[779:787,]

## read locations

#meta =  read.csv("/home/joel/data/GCOS/points_all.txt")
#samples = extract(landform,meta[pkvec,2:3])

#===============================================================================
#	Read locations
#===============================================================================

# read locations
posits = intersect(shp,landform)
samples = extract(landform,posits)
stat = posits$STAT_AB
Nval = length(stat)
# read in data
myfilenames = paste0("/home/joel/data/GCOS/sp_",stat,".txt")
myList <- lapply(myfilenames, read.csv) 


#===============================================================================
#			New plot routine
#===============================================================================



# generic plot pars
lwd=3
pdf(plotout,width=7, height=12 )

par(mfrow=c(ceiling(sqrt(Nval)),ceiling(sqrt(Nval))))
par(mfrow=c(3,1))
for ( j in 1:Nval ) {

## POSTERIOR
##==========================Compute median=====================================

# sample ID
id=samples[j]

sample= id
ndays = length(myarray_swe[ , 1, 1])

median.vec = c()
for ( i in 1: ndays){

mu = myarray_swe[ i, sample, ]
w = mylist[[ sample ]]

# fill missing ensemble weights with 0
index = as.numeric(names(mylist[[ sample ]]))
df=data.frame(index,w)
df.new = data.frame(index = 1:100)
df.fill = merge(df.new,df, all.x = TRUE)
wfill=df.fill$Freq
wfill[which(is.na(wfill))]<-0


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

mu = myarray_swe[ i, sample, ]
w = mylist[[ sample ]]

# fill missing ensemble weights with 0
index = as.numeric(names(mylist[[ sample ]]))
df=data.frame(index,w)
df.new = data.frame(index = 1:100)
df.fill = merge(df.new,df, all.x = TRUE)
wfill=df.fill$Freq
wfill[which(is.na(wfill))]<-0


df = data.frame(mu, wfill )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.05)
low.vec = c(low.vec, med$y)
}


high.vec = c()
for ( i in 1: ndays){

mu = myarray_swe[ i, sample, ]
w = mylist[[ sample ]]

# fill missing ensemble weights with 0
index = as.numeric(names(mylist[[ sample ]]))
df=data.frame(index,w)
df.new = data.frame(index = 1:100)
df.fill = merge(df.new,df, all.x = TRUE)
wfill=df.fill$Freq
wfill[which(is.na(wfill))]<-0


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
ndays = length(myarray_swe[ , 1, 1])

median.prior = c()
for ( i in 1: ndays){

mu = myarray_swe[ i, sample, ]
w = rep(0.01,100)

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
ndays = length(myarray_swe[ , 1, 1])

low.prior = c()
for ( i in 1: ndays){

mu = myarray_swe[ i, sample, ]
w = rep(0.01,100)

df = data.frame(mu, w )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$w),dfOrder$mu , xout=0.05)
low.prior = c(low.prior, med$y)
}

# 95%
id=samples[j]

sample= id
ndays = length(myarray_swe[ , 1, 1])

high.prior = c()
for ( i in 1: ndays){

mu = myarray_swe[ i, sample, ]
w = rep(0.01,100)

df = data.frame(mu, w )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$w),dfOrder$mu , xout=0.95)
high.prior = c(high.prior, med$y)
}







simindex=paste0('S',formatC(id, width=5,flag='0'))# samples[1]

#
valdat<- myList[[j]]
# convert obs timestamps
d = strptime(valdat$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M') #geotop format
#d3=format(d, '%Y/%m/%d') # obsvec format

#index of sim data in obs
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

# index of obs in sim data
simIndexVal = which(d2 %in% dat$Date12.DDMMYYYYhhmm.)


#get prior
dat = read.table(paste0(priorwd,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
prior_swe = dat$snow_water_equivalent.mm.

# obs
val = valdat$SWE.mm[simIndexVal]

#get posterioi
post_swe = we_mat[,id]
post_sca = we_mat_sca[,id]*1000
# rmse
error = val - post_swe[obsIndexVal]
rms = rmse(error)

# plot prior,post, obs
# plot prior,post, obs
plot(median.prior, ylim=c(0,1000),col='blue', type='l',lwd=3,xaxt = "n",main=paste0(stat[j],' RMSE=',round(rms,2))) # prior
for (i in 1:nens){lines(myarray_swe[,id,i], col='grey')}

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
# posterior mode
#lines(post_swe,col='green',lwd=lwd) #post

#obs
points(obsIndexVal,val, lwd=lwd, cex=2, col='black',pch=24) #obs

# modal prior
#lines(prior_swe, col='red',lwd=3)


#lines(ma(post,20), col='green',lwd=3)
#lines(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='orange',lwd=3)
#points(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='black',cex=2, pch=3)
#lines(post_sca, col='red', lwd=lwd , lty=2)
axis(side=1,at=1:length(dat$Date12.DDMMYYYYhhmm.) , labels=substr(dat$Date12.DDMMYYYYhhmm.,1,10),tick=FALSE)
legend("topright",c("SWE_prior","SWE_post_median", "SWE_post_mode", "SWE_obs" , "ENSEMBLE"),col= c("red","blue", "green","black", "grey"), lty=c(1,1,1,NA, 1),pch=c(NA,NA,NA, 24,NA),lwd=lwd)

}

dev.off()

#===============================================================================
#			Grid level fsca plots
#===============================================================================
priorfsca = apply(myarray, MARGIN=c(1,3), FUN='sum')/Nclust

# reindex to modis obs
gfsca = priorfsca[obsIndex.MOD,]
minprior = apply(gfsca, MARGIN=c(1), FUN='min')
maxprior = apply(gfsca, MARGIN=c(1), FUN='max')


plot(gfsca[,1], type='l')
for (i in 2:nens){lines(gfsca[,i], type='l')}
 
rst = cellStats(rstack, 'mean', na.rm=T)
lines(rst/100, col='red')
postfsca = apply(we_mat_sca, MARGIN=c(1), FUN='sum')/Nclust
lines(postfsca[obsIndex.MOD], col='blue')
lines(minprior, col='green')
lines(maxprior, col='green')

# bounday plots
y=c(maxprior, rev(minprior))
x=c(1:length(maxprior), length(maxprior):1)

polygon (x,y, col='green')
lines(postfsca[obsIndex.MOD], col='blue', lwd=3)



cloudThreshold <-0.2
cloudinessMOD = cellStats(is.na(rstack),'sum') / ncell(rstack)
cloudfreeIndex= which(cloudinessMOD < cloudThreshold)
#rst = cellStats(rstack, 'mean', na.rm=T)


pfsca = postfsca[obsIndex.MOD]
# replot with cloudfree index
plot(gfsca[cloudfreeIndex,1], type='l', main = paste0("Grid mean fSCA plot, grid=", gridN, "sdThresh=", sdThresh), xlab= 'doy', ylab='fSCA', xaxt='n')
for (i in 2:nens){lines(gfsca[cloudfreeIndex,i], type='l')} 
lines(rst[cloudfreeIndex]/100, col='red')
lines(pfsca[cloudfreeIndex], col='blue')
# bounday plots
y=c(maxprior[cloudfreeIndex], rev(minprior[cloudfreeIndex]))
x=c(1:length(cloudfreeIndex), length(cloudfreeIndex):1)
polygon (x,y, col='green')
lines(rst[cloudfreeIndex]/100, col='red', lwd=2)
points(rst[cloudfreeIndex]/100, col='red', lwd=2,pch=24)
lines(pfsca[cloudfreeIndex], col='blue', lwd=2)
legend("topright",c("sca_prior", "sca_post_median", "sca_obs" ),col= c("green", "blue","red"), lty=c(1,1,1),lwd=lwd)
axis(side = 1, at =1:length(cloudfreeIndex) , labels=obsTS$x[cloudfreeIndex] )


#===============================================================================
#			quantile plots
#===============================================================================

# - time *ensemble for sample n

sample= 107
ndays = length(myarray_swe[ , 1, 1])

median.vec = c()
for ( i in 1: ndays){

mu = myarray_swe[ i, sample, ]
DF.NEW <- 1:nens
DF.NEW <- merge(DF.NEW, mu) 

w = mylist[[ sample ]]
df = data.frame(mu, w )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$Freq))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$Freq),dfOrder$mu , xout=0.5)
median.vec = c(median.vec, med$y)
}

##===============================================================================
##			an
##===============================================================================
#pdf(plotout,width=7, height=12 )
#par(mfrow=c(3,1))
#lwd=3
## SAMPLE CORRESPONDING TO TR
#simindex = "S00006" # samples[1]
#id=6

## convert obs timestamps
#d = strptime(an$DATUM, format="%d.%m.%Y")
#d2=format(d, '%d/%m/%Y %H:%M') #geotop format
##d3=format(d, '%Y/%m/%d') # obsvec format

## GET CORRESPONDING SIM TIMESTAMPS of profile obs 
#obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

##get prior
#dat = read.table(paste0(priorwd,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
#prior_swe = dat$snow_water_equivalent.mm.

## obs
#val = an$SWE.mm

##get posterioi
#post_swe = we_mat[,id]
#post_sca = we_mat_sca[,id]*1000
## rmse
#error = val - post_swe[obsIndexVal]
#rms = rmse(error)

## plot prior,post, obs
## plot prior,post, obs
#plot(prior_swe, ylim=c(0,1000),col='blue', type='l',lwd=3,xaxt = "n",main=paste0('RMSE=',round(rms,2))) # prior
#for (i in 1:100){lines(myarray_swe[,id,i], col='grey')}
#lines(post_swe,col='red',lwd=lwd) #post
#points(obsIndexVal,val, lwd=lwd, cex=2, col='black',pch=24) #obs
#lines(prior_swe, col='blue',lwd=3)
##lines(ma(post,20), col='green',lwd=3)
##lines(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='orange',lwd=3)
##points(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='black',cex=2, pch=3)
##lines(post_sca, col='red', lwd=lwd , lty=2)
#axis(side=1,at=1:length(dat$Date12.DDMMYYYYhhmm.) , labels=substr(dat$Date12.DDMMYYYYhhmm.,1,10),tick=FALSE)
#legend("topright",c("SWE_prior", "SWE_post", "SWE_obs" , "ENSEMBLE"),col= c("blue", "red","black", "grey"), lty=c(1,1,NA, 1),pch=c(NA,NA,24,NA),lwd=lwd)
##===============================================================================
##			trUBSEE tr
##===============================================================================
## SAMPLE CORRESPONDING TO TR
#simindex = "S00121" # samples[1]
#id=121

## convert obs timestamps
#d = strptime(tr$DATUM, format="%d.%m.%Y")
#d2=format(d, '%d/%m/%Y %H:%M')

## GET CORRESPONDING SIM TIMESTAMPS of profile obs 
#obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

##get prior
#dat = read.table(paste0(priorwd,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
#prior_swe = dat$snow_water_equivalent.mm.

## obs
#val = tr$SWE.mm

##get posterioi
#post_swe = we_mat[,id]
#post_sca = we_mat_sca[,id]*1000

## rmse
#error = val - post_swe[obsIndexVal]
#rms = rmse(error)

## plot prior,post, obs
#plot(prior_swe, ylim=c(0,1000),col='blue', type='l',lwd=3,xaxt = "n",main=paste0('RMSE=',round(rms,2))) # prior
#for (i in 1:100){lines(myarray_swe[,id,i], col='grey')}
#lines(post_swe,col='red',lwd=lwd) #post
#points(obsIndexVal,val, lwd=lwd, cex=2, col='black',pch=24) #obs
#lines(prior_swe, col='blue',lwd=3)
##lines(ma(post,20), col='green',lwd=3)
##lines(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='orange',lwd=3)
##points(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='black',cex=2, pch=3)
##lines(post_sca, col='red', lwd=lwd , lty=2)
#axis(side=1,at=1:length(dat$Date12.DDMMYYYYhhmm.) , labels=substr(dat$Date12.DDMMYYYYhhmm.,1,10),tick=FALSE)
#legend("topright",c("SWE_prior", "SWE_post", "SWE_obs" , "ENSEMBLE"),col= c("blue", "red","black", "grey"), lty=c(1,1,NA, 1),pch=c(NA,NA,24,NA),lwd=lwd)

##===============================================================================
##			UL
##===============================================================================
## SAMPLE CORRESPONDING TO TR
#simindex = "S00006" # samples[1]
#id=6

## convert obs timestamps
#d = strptime(ul$DATUM, format="%d.%m.%Y")
#d2=format(d, '%d/%m/%Y %H:%M')

## GET CORRESPONDING SIM TIMESTAMPS of profile obs 
#obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

##get prior
#dat = read.table(paste0(priorwd,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
#prior_swe = dat$snow_water_equivalent.mm.

## obs
#val = ul$SWE.mm

##get posterioi
#post_swe = we_mat[,id]
#post_sca = we_mat_sca[,id]*1000

## rmse
#error = val - post_swe[obsIndexVal]
#rms = rmse(error)

## plot prior,post, obs swe
## plot prior,post, obs
#plot(prior_swe, ylim=c(0,1000),col='blue', type='l',lwd=3,xaxt = "n",main=paste0('RMSE=',round(rms,2))) # prior
#for (i in 1:100){lines(myarray_swe[,id,i], col='grey')}
#lines(post_swe,col='red',lwd=lwd) #post
#points(obsIndexVal,val, lwd=lwd, cex=2, col='black',pch=24) #obs
#lines(prior_swe, col='blue',lwd=3)
##lines(ma(post,20), col='green',lwd=3)
##lines(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='orange',lwd=3)
##points(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='black',cex=2, pch=3)
##lines(post_sca, col='red', lwd=lwd , lty=2)
#axis(side=1,at=1:length(dat$Date12.DDMMYYYYhhmm.) , labels=substr(dat$Date12.DDMMYYYYhhmm.,1,10),tick=FALSE)
#legend("topright",c("SWE_prior", "SWE_post", "SWE_obs" , "ENSEMBLE"),col= c("blue", "red","black", "grey"), lty=c(1,1,NA, 1),pch=c(NA,NA,24,NA),lwd=lwd)

##legend("topright",c("SWE_prior", "SWE_post", "SWE_obs", "fSCA_post", "fSCA_obs"),col= c("blue", "red","black", "red", "black"), lty=c(1,1,1,NA,1),pch=c(NA,NA,NA,1,NA),lwd=lwd)

## plot prior,post, obs SCA



#dev.off()


#prior_swe[prior_swe <13] <- 0
#plot(prior_sca, ylim=c(0,1000),col='blue', type='l',lwd=3,xaxt = "n",main=paste0('RMSE=',round(rms,2))) # prior
#for (i in 1:100){lines(myarray_swe[,id,i], col='grey')}
#lines(post_sca,col='red',lwd=lwd) #post
#points(obsIndexVal,val, lwd=lwd, cex=2, col='black',pch=24) #obs
#lines(prior_swe, col='blue',lwd=3)
##lines(ma(post,20), col='green',lwd=3)
##lines(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='orange',lwd=3)
##points(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='black',cex=2, pch=3)
##lines(post_sca, col='red', lwd=lwd , lty=2)
#axis(side=1,at=1:length(dat$Date12.DDMMYYYYhhmm.) , labels=substr(dat$Date12.DDMMYYYYhhmm.,1,10),tick=FALSE)
#legend("topright",c("SWE_prior", "SWE_post", "SWE_obs" , "ENSEMBLE"),col= c("blue", "red","black", "grey"), lty=c(1,1,NA, 1),pch=c(NA,NA,24,NA),lwd=lwd)

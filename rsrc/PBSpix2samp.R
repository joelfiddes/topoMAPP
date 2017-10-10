# dependency
library("foreach")
library("doParallel")
require(raster) 

# env
#wd = "/home/joel/sim/ensembler3/"
#priorwd = "/home/joel/sim/da_test2/" 
wd = "/home/joel/sim/ensembler_scale_sml/" 
priorwd = "/home/joel/sim/scale_test_sml/"
grid=9
# IO files
plotout=("~/plot_fscacorrect_allcloud2.pdf")
load( paste0(wd,"wmat_2.rd"))
rstack = brick(paste0(priorwd,"fsca_stack.tif"))
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
sdThresh <- 0

# cores used in parallel jobs
cores=4
 
 
# ======== code ===================

# readin
landform = raster(paste0(wd,"ensemble0/grid",grid,"/landform.tif"))

# crop rstack to landform as landform represent grid and rstack the domain not necessarily the same
rstack = crop(rstack, landform)

# crop rstack to landform as landform represent grid and rstack the domain not necessarily the same

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
 
 we_mat=c()
 for ( i in 1:Nclust ){
	# vector of ensemble IDs
	ids = as.numeric(names(mylist[[i]]))
	
	# vector of ensemble weights 
	weights = as.numeric((mylist[[i]]))
	 #weights[ which.max(weights) ]<-1
	# weights[weights<1]<-0
	# multiply filtered timeseries for sample 1 and ensembles memebers "ids"
	we <-  myarray_swe[,i,ids] %*%weights
	#if(!is.null(dim(we))){we = rowSums(we)}
	we_mat=cbind(we_mat, we) # time * samples weighted 
 
 }
	
#===============================================================================
#			compute weight ensemble per sample - posterior sca
#===============================================================================
 
 we_mat_sca=c()
 for ( i in 1:Nclust ){
	# vector of ensemble IDs
	ids = as.numeric(names(mylist[[i]]))
	
	# vector of ensemble weights 
	weights = as.numeric((mylist[[i]]))
	 
	
	# multiply filtered timeseries for sample 1 and ensembles memebers "ids"
	we <-  myarray[,i,ids] %*%weights
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


pkvec=c(2:4)
tr = read.csv("/home/joel/data/GCOS/sp_2TR.txt")
ul = read.csv("/home/joel/data/GCOS/sp_4UL.txt")
an = read.csv("/home/joel/data/GCOS/sp_2AN.txt")

#subset
tr = tr[539:543,]
ul = ul[422:427,]
an = an[779:787,]

# read locations
meta =  read.csv("/home/joel/data/GCOS/points_all.txt")
samples = extract(landform,meta[pkvec,2:3])

#===============================================================================
#			an
#===============================================================================
par(mfrow=c(2,3))

ma <- function(x,n=5){filter(x,rep(1/n,n), sides=2)}


# SAMPLE CORRESPONDING TO TR
simindex = "S00006" # samples[1]
id=6

# convert obs timestamps
d = strptime(an$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M') #geotop format
#d3=format(d, '%Y/%m/%d') # obsvec format

# GET CORRESPONDING SIM TIMESTAMPS of profile obs 
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#get prior
dat = read.table(paste0(priorwd,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
prior = dat$snow_water_equivalent.mm.[obsIndexVal]

# obs
val = an$SWE.mm

#get posterioi
post = we_mat[,id]


# plot prior,post, obs based on "bestguess"
plot(prior, ylim=c(0,1000),col='red', type='l',lwd=3,xaxt = "n") # prior
for (i in 1:100){lines(myarray_swe[obsIndexVal,id,i], col='grey')}
lines(post[obsIndexVal],col='blue',lwd=3) #post
lines(val, lwd=3) #obs

axis(side=1, at = 1:length(d2), labels=substr(d2,1,10))
legend("topright",c("prior", "postM", "obs"),col= c("red","blue","black"), lty=1,lwd=3)
error = val - post[obsIndexVal]
rmse(error)
#===============================================================================
#			trUBSEE tr
#===============================================================================
# SAMPLE CORRESPONDING TO TR
simindex = "S00121" # samples[1]
id=121

# convert obs timestamps
d = strptime(tr$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M')

# GET CORRESPONDING SIM TIMESTAMPS of profile obs 
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#get prior
dat = read.table(paste0(priorwd,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
prior = dat$snow_water_equivalent.mm.[obsIndexVal]

# obs
val = tr$SWE.mm

#get posterioi
post = we_mat[,id]


# plot prior,post, obs
plot(prior, ylim=c(0,1000),col='red', type='l',lwd=3,xaxt = "n") # prior
for (i in 1:100){lines(myarray_swe[obsIndexVal,id,i], col='grey')}
lines(post[obsIndexVal],col='blue',lwd=3) #post
lines(val, lwd=3) #obs
legend("topright",c("prior", "postM", "obs"),col= c("red","blue","black"), lty=1,lwd=3)
axis(side=1, at = 1:length(d2), labels=substr(d2,1,10))
error = val - post[obsIndexVal]
rmse(error)


#===============================================================================
#			UL
#===============================================================================
# SAMPLE CORRESPONDING TO TR
simindex = "S00006" # samples[1]
id=6

# convert obs timestamps
d = strptime(ul$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M')

# GET CORRESPONDING SIM TIMESTAMPS of profile obs 
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#get prior
dat = read.table(paste0(priorwd,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
prior = dat$snow_water_equivalent.mm.[obsIndexVal]

# obs
val = ul$SWE.mm

#get posterioi
post = we_mat[,id]


# plot prior,post, obs based on "bestguess"
plot(prior, ylim=c(0,1000),col='red', type='l',lwd=3,xaxt = "n") # prior
for (i in 1:100){lines(myarray_swe[obsIndexVal,id,i], col='grey')}
lines(post[obsIndexVal],col='blue',lwd=3) #post
lines(val, lwd=3) #obs
legend("topright",c("prior", "postM", "obs"),col= c("red","blue","black"), lty=1,lwd=3)
axis(side=1, at = 1:length(d2), labels=substr(d2,1,10))
error = val - post[obsIndexVal]
rmse(error)




























#===============================================================================
#			an
#===============================================================================
pdf(plotout,width=7, height=12 )
par(mfrow=c(3,1))
lwd=3
# SAMPLE CORRESPONDING TO TR
simindex = "S00006" # samples[1]
id=6

# convert obs timestamps
d = strptime(an$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M') #geotop format
#d3=format(d, '%Y/%m/%d') # obsvec format

# GET CORRESPONDING SIM TIMESTAMPS of profile obs 
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#get prior
dat = read.table(paste0(priorwd,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
prior_swe = dat$snow_water_equivalent.mm.

# obs
val = an$SWE.mm

#get posterioi
post_swe = we_mat[,id]
post_sca = we_mat_sca[,id]*1000
# rmse
error = val - post_swe[obsIndexVal]
rms = rmse(error)

# plot prior,post, obs
# plot prior,post, obs
plot(prior_swe, ylim=c(0,1000),col='blue', type='l',lwd=3,xaxt = "n",main=paste0('RMSE=',round(rms,2))) # prior
for (i in 1:100){lines(myarray_swe[,id,i], col='grey')}
lines(post_swe,col='red',lwd=lwd) #post
points(obsIndexVal,val, lwd=lwd, cex=2, col='black',pch=24) #obs
lines(prior_swe, col='blue',lwd=3)
#lines(ma(post,20), col='green',lwd=3)
#lines(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='orange',lwd=3)
#points(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='black',cex=2, pch=3)
#lines(post_sca, col='red', lwd=lwd , lty=2)
axis(side=1,at=1:length(dat$Date12.DDMMYYYYhhmm.) , labels=substr(dat$Date12.DDMMYYYYhhmm.,1,10),tick=FALSE)
legend("topright",c("SWE_prior", "SWE_post", "SWE_obs" , "ENSEMBLE"),col= c("blue", "red","black", "grey"), lty=c(1,1,NA, 1),pch=c(NA,NA,24,NA),lwd=lwd)
#===============================================================================
#			trUBSEE tr
#===============================================================================
# SAMPLE CORRESPONDING TO TR
simindex = "S00121" # samples[1]
id=121

# convert obs timestamps
d = strptime(tr$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M')

# GET CORRESPONDING SIM TIMESTAMPS of profile obs 
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#get prior
dat = read.table(paste0(priorwd,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
prior_swe = dat$snow_water_equivalent.mm.

# obs
val = tr$SWE.mm

#get posterioi
post_swe = we_mat[,id]
post_sca = we_mat_sca[,id]*1000

# rmse
error = val - post_swe[obsIndexVal]
rms = rmse(error)

# plot prior,post, obs
plot(prior_swe, ylim=c(0,1000),col='blue', type='l',lwd=3,xaxt = "n",main=paste0('RMSE=',round(rms,2))) # prior
for (i in 1:100){lines(myarray_swe[,id,i], col='grey')}
lines(post_swe,col='red',lwd=lwd) #post
points(obsIndexVal,val, lwd=lwd, cex=2, col='black',pch=24) #obs
lines(prior_swe, col='blue',lwd=3)
#lines(ma(post,20), col='green',lwd=3)
#lines(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='orange',lwd=3)
#points(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='black',cex=2, pch=3)
#lines(post_sca, col='red', lwd=lwd , lty=2)
axis(side=1,at=1:length(dat$Date12.DDMMYYYYhhmm.) , labels=substr(dat$Date12.DDMMYYYYhhmm.,1,10),tick=FALSE)
legend("topright",c("SWE_prior", "SWE_post", "SWE_obs" , "ENSEMBLE"),col= c("blue", "red","black", "grey"), lty=c(1,1,NA, 1),pch=c(NA,NA,24,NA),lwd=lwd)

#===============================================================================
#			UL
#===============================================================================
# SAMPLE CORRESPONDING TO TR
simindex = "S00006" # samples[1]
id=6

# convert obs timestamps
d = strptime(ul$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M')

# GET CORRESPONDING SIM TIMESTAMPS of profile obs 
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#get prior
dat = read.table(paste0(priorwd,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
prior_swe = dat$snow_water_equivalent.mm.

# obs
val = ul$SWE.mm

#get posterioi
post_swe = we_mat[,id]
post_sca = we_mat_sca[,id]*1000

# rmse
error = val - post_swe[obsIndexVal]
rms = rmse(error)

# plot prior,post, obs swe
# plot prior,post, obs
plot(prior_swe, ylim=c(0,1000),col='blue', type='l',lwd=3,xaxt = "n",main=paste0('RMSE=',round(rms,2))) # prior
for (i in 1:100){lines(myarray_swe[,id,i], col='grey')}
lines(post_swe,col='red',lwd=lwd) #post
points(obsIndexVal,val, lwd=lwd, cex=2, col='black',pch=24) #obs
lines(prior_swe, col='blue',lwd=3)
#lines(ma(post,20), col='green',lwd=3)
#lines(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='orange',lwd=3)
#points(obsIndex.MOD[start:end],pointObs[4,start:end]*10, col='black',cex=2, pch=3)
#lines(post_sca, col='red', lwd=lwd , lty=2)
axis(side=1,at=1:length(dat$Date12.DDMMYYYYhhmm.) , labels=substr(dat$Date12.DDMMYYYYhhmm.,1,10),tick=FALSE)
legend("topright",c("SWE_prior", "SWE_post", "SWE_obs" , "ENSEMBLE"),col= c("blue", "red","black", "grey"), lty=c(1,1,NA, 1),pch=c(NA,NA,24,NA),lwd=lwd)

#legend("topright",c("SWE_prior", "SWE_post", "SWE_obs", "fSCA_post", "fSCA_obs"),col= c("blue", "red","black", "red", "black"), lty=c(1,1,1,NA,1),pch=c(NA,NA,NA,1,NA),lwd=lwd)

# plot prior,post, obs SCA



dev.off()


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

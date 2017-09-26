#in:
# tObs=vector timestamps of obs, size = No*1 [16]
# MODISgrid=raster stack of obs covering domain = No*MODpix^2 [16*50*50]

# need inverse of landform (each smlPix has cluster id), overlay bigPix grid on 
# smlPix grid, extract sample IDs per pixel (could be ragged dataframe for geolocation issues)
#read in landform
#read in MODISgrid
#R=0.016

## 
#pixelloop i in 1:n:
#	- extract sampids for bigPix[i]
#	- compute fSCAObs per pixel  (this is Y=16*1)	
#	ensemble loop j in 1:n:
#		- compute fSCATsub per pixel[i] using sampids for each ensemble[j] (this is HX=16*100)
#		end	
#	- w=PBS(HX,Y,R)
#	- save w (100)
#	end
## out:	
#matrix of w = 25000*100 [pix * ensemble]
#convert to rasterstack?
 
# ======== code ===================

#source fast PBS
source("./rsrc/PBS.R") 

# variables
nens=100
R=0.016
Nclust=50
sdThresh <- 0
 
require(raster) 

# readin
landform = raster("/home/joel/sim/ensembler2/ensemble0/grid1/landform.tif")
rstack = brick("/home/joel/sim/da_test2/fsca_stack.tif")
obsTS = read.csv("/home/joel/sim/da_test2/fsca_dates.csv")
wd = "/home/joel/sim/ensembler2/"
sampMembers = table(getValues(landform))
totalMembers= sum(sampMembers)

# crop rstack to landform as landform represent grid and rstack the domain not necessarily the same

# pixel based timeseries 
pixTS = extract( rstack , 1:ncell(rstack) )

# total number of MODIS pixels
npix = ncell( rstack)

#pixel loop
#npix_vec=c()

# retrieve results matrix: ensemble members * samples * timestamps
# NEED TO SELECT ONLY TIMESTAMPOS in obsTS 
d=strptime(obsTS$x, format='%Y-%m-%d')
d2=format(d, '%d/%m/%Y %H:%M')

dat = read.table(paste0(wd,"ensemble0/grid1/S00001/out/surface.txt"), sep=',', header=T)
obsIndex = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#convert obsTS to geotop time get index of results that fit obsTS
rstStack=stack()
for (i in 1: nens){ #python index

	resMat=c()
	for (j in 1: Nclust){ 
		simindex=paste0('S',formatC(j, width=5,flag='0'))
		dat = read.table(paste0(wd,"ensemble",i-1,"/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
		
		
		resMat = cbind(resMat,dat$snow_water_equivalent.mm.[obsIndex])
		rst=raster(resMat)
	}
rstStack=stack(rstStack, rst)
myarray = as.array(rstStack)
}

# convert swe > sdThresh to snowcover = TRUE/1
# dimension = time * sample * ensemble
myarray[myarray>sdThresh]<-1

#vectorise all below

#wmat=c()
#t1 <- Sys.time()
#for (i in 1 : npix)
#	{
#	print(i)
	
	# Extract pixel based timeseries of MODIS obs and scale
	#obs = pixTS[i,] /100
	obs <- cellStats(rstack, 'mean') /100
	
	HX=c()
	for( i in 1:100){
	
	tivec=c()
	for( j in 1:40){
	ti = sum(myarray[j,,i]*sampMembers )/totalMembers
	tivec=c(tivec,ti)
	
	}
	HX=cbind(HX,tivec)
	}	

#apply time filter
start=15
end=40
HX=HX[start:end,]	
obs=obs[start:end]
# run particle batch smoother	
w = PBS(HX,obs, R)	

#===============================================================================
#			plot ensembles SCA
#===============================================================================
par(mfrow=c(4,2))

# compute rmse ensemble v obs fSCA
rmse <- function(error)
{
    sqrt(mean(error^2))
}

print("minimum ensemble rmse")
error = obs - HX
min(apply(error, FUN=rmse, MARGIN=2))

# this is same as bestEnsemble!
minRMSE = which.min(apply(error, FUN=rmse, MARGIN=2))

# plot obs and all ensembles
mycols=rainbow(40)
plot(obs,type='l', ylim=c(0,max(HX)),col='black',lwd=3, main="Ensemble fSCA")
for( i in 1:40){lines(HX[,i],col=mycols[i],lwd=1)}
lines(obs,type='l',col='black',lwd=3)

# best guess and MODIS OBS
#plot(obs,type='l', ylim=c(0,max(HX)),col='black',lwd=3)
#lines(HX[,which.max(w)],col="red",lwd=1)

# prior
	# compute time * samp matrix
	resMat=c()
	for (j in 1: Nclust){ 
		simindex=paste0('S',formatC(j, width=5,flag='0'))
		dat = read.table(paste0("/home/joel/sim/da_test2/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
		resMat = cbind(resMat,dat$snow_water_equivalent.mm.[obsIndex])
	}

	# convert swe > sdThresh to snowcover = TRUE/1
	resMat[resMat>sdThresh]<-1
	
	# compute mean domain fSCA at each timestep of obs
	priorDomain=c()
	for( j in 1:40){
	ti = sum(resMat[j,]*sampMembers )/totalMembers
	priorDomain=c(priorDomain,ti)
	}

#winning ensemble domain level
bestEnsemble = which.max(w)
minRMSE==bestEnsemble #test identical

# domain wide fSCA
plot(obs,type='l', ylim=c(0,max(HX)),col='black',lwd=3, main="Domain wide fSCA")
lines(HX[,which.max(w)],col="blue",lwd=3) # post
lines(priorDomain[start:end],col="red",lwd=3) 
legend("topright",c("prior", "post", "obs"),col= c("red","blue","black"), lty=1,lwd=3)

print("prior rmse")
error = obs - priorDomain[start:end]
rmse(error)
#===============================================================================
#			validation SWE
#===============================================================================

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
# SAMPLE CORRESPONDING TO TR
simindex = "S00021" # samples[1]

print(paste0("best guess is emnnsemble:", bestEnsemble))


# convert obs timestamps
d = strptime(an$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M')

# GET CORRESPONDING SIM TIMESTAMPS
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#get prior
dat = read.table(paste0("/home/joel/sim/da_test2/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
prior = dat$snow_water_equivalent.mm.[obsIndexVal]

# obs
val = an$SWE.mm



# plot ensemble of one samople
mycols=rainbow(40)
plot(prior, ylim=c(0,1000),col='red', type='l', lwd=3) #prior
for( i in 1:40){
dat = read.table(paste0("/home/joel/sim/ensembler2/ensemble",i-1,"/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
lines(dat$snow_water_equivalent.mm.[obsIndexVal],col=mycols[i])}
lines(prior, ylim=c(0,1000),col='red', type='l',lty=2, lwd=3) 
lines(val)

# post best guess
dat = read.table(paste0("/home/joel/sim/ensembler2/ensemble",bestEnsemble,"/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
post = dat$snow_water_equivalent.mm.[obsIndexVal]


# plot prior,post, obs based on "bestguess"
plot(prior, ylim=c(0,1000),col='red', type='l',lwd=3) # prior
lines(val, lwd=3) #obs
lines(post,col='blue',lwd=3) #post
legend("topright",c("prior", "post", "obs"),col= c("red","blue","black"), lty=1,lwd=3)


#===============================================================================
#			trUBSEE tr
#===============================================================================
# SAMPLE CORRESPONDING TO TR
simindex = "S00007" # samples[1]

print(paste0("best guess is emnnsemble:", bestEnsemble))


# convert obs timestamps
d = strptime(tr$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M')

# GET CORRESPONDING SIM TIMESTAMPS
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#get prior
dat = read.table(paste0("/home/joel/sim/da_test2/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
prior = dat$snow_water_equivalent.mm.[obsIndexVal]

# obs
val = tr$SWE.mm



# plot ensemble of one samople
mycols=rainbow(40)
plot(prior, ylim=c(0,1000),col='red', type='l', lwd=3) #prior
for( i in 1:40){
dat = read.table(paste0("/home/joel/sim/ensembler2/ensemble",i-1,"/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
lines(dat$snow_water_equivalent.mm.[obsIndexVal],col=mycols[i])}
lines(prior, ylim=c(0,1000),col='red', type='l',lty=2, lwd=3) 
lines(val)

# post best guess
dat = read.table(paste0("/home/joel/sim/ensembler2/ensemble",bestEnsemble,"/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
post = dat$snow_water_equivalent.mm.[obsIndexVal]


# plot prior,post, obs based on "bestguess"
plot(prior, ylim=c(0,1000),col='red', type='l',lwd=3) # prior
lines(val, lwd=3) #obs
lines(post,col='blue',lwd=3) #post
legend("topright",c("prior", "post", "obs"),col= c("red","blue","black"), lty=1,lwd=3)

#===============================================================================
#			UL
#===============================================================================
# SAMPLE CORRESPONDING TO TR
simindex = "S00036" # samples[1]

print(paste0("best guess is emnnsemble:", bestEnsemble))


# convert obs timestamps
d = strptime(ul$DATUM, format="%d.%m.%Y")
d2=format(d, '%d/%m/%Y %H:%M')

# GET CORRESPONDING SIM TIMESTAMPS
obsIndexVal = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#get prior
dat = read.table(paste0("/home/joel/sim/da_test2/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
prior = dat$snow_water_equivalent.mm.[obsIndexVal]

# obs
val = ul$SWE.mm



# plot ensemble of one samople
mycols=rainbow(40)
plot(prior, ylim=c(0,1000),col='red', type='l', lwd=3) #prior
for( i in 1:40){
dat = read.table(paste0("/home/joel/sim/ensembler2/ensemble",i-1,"/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
lines(dat$snow_water_equivalent.mm.[obsIndexVal],col=mycols[i])}
lines(prior, ylim=c(0,1000),col='red', type='l',lty=2, lwd=3) 
lines(val)

# post best guess
dat = read.table(paste0("/home/joel/sim/ensembler2/ensemble",bestEnsemble,"/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
post = dat$snow_water_equivalent.mm.[obsIndexVal]


# plot prior,post, obs based on "bestguess"
plot(prior, ylim=c(0,1000),col='red', type='l',lwd=3) # prior
lines(val, lwd=3) #obs
lines(post,col='blue',lwd=3) #post
legend("topright",c("prior", "post", "obs"),col= c("red","blue","black"), lty=1,lwd=3)



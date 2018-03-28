#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)
#SOURCE
source("./rsrc/toposub_src.R")
#====================================================================
# PARAMETERS/ARGS
#====================================================================
#args <- 	commandArgs(trailingOnly=TRUE)
#gridpath <- args[1]
#Nclust <-args[2]
#targV <- 	args[3]
#date <- 	args[4]

# get obs make Na mask
Nclust <- 150
targV <- "snow_water_equivalent.mm."
date <- "21/05/2016 00:00"
priorwd = "/home/joel/mnt/myserver/nas/sim/SIMS_JAN18/gcos_cor/"
rstack = brick(paste0(priorwd,"fsca_stack.tif"))
obsTS = read.csv(paste0(priorwd,"fsca_dates.csv"))
mod=rstack[[6]]
mask <- mod
mask[is.na(mask)==T]<-999
mask[mask<999]<-NA
gridpath=paste0(priorwd, "/grid1/")

#t1 = Sys.time()
#rmsvec=c()
#for (n in 0:99){


#gridpath = paste0("/home/joel/sim/ensembler3/ensemble",n,"/grid1")
resultsVec <- c()
print(n)
for (i in 1:Nclust){

# returns datapoint given sampleN and date and targV
datpoint = sampleResultsNow(gridpath = gridpath, sampleN = i, targV = targV, date = date)
resultsVec <- c(resultsVec, datpoint)	
}

landform<-raster(paste0(gridpath, "/landform.tif")	)
rst = crispSpatialNow(resultsVec, landform)
mod = crop(mod,landform)
#=======================
sca <- rst
sca[sca<13]<-NA
sca[sca>=13]<-1

r = sca
s = mod
d=aggregate(r, fact=c(round(dim(r)[1]/dim(s)[1]),round(dim(r)[2]/dim(s)[2])), fun='mean') #fact equals r/s for cols and rows
e=resample(d, s,  method="ngb")



s <- s/100

rmse <- function(error)
{
    sqrt(mean(error^2,na.rm=T))
}
error = getValues(s)-getValues(e)

rms = rmse(error)
rms
cor(getValues(s),getValues(e), use='complete.obs')

par(mfrow=c(1,3))
plot(e, main = rms)
plot(s)
plot(mask, add=T, legend=F, col='red')

plot(e-s)

#rmsvec=c(rmsvec, rms)


# compare to priorwd

gridpath = "/home/joel/sim/da_test2/grid1"

resultsVec <- c()

for (i in 1:Nclust){

# returns datapoint given sampleN and date and targV
datpoint = sampleResultsNow(gridpath = gridpath, sampleN = i, targV = targV, date = date)
resultsVec <- c(resultsVec, datpoint)	
}

landform<-raster(paste0(gridpath, "/landform.tif")	)
prior = crispSpatialNow(resultsVec, landform)

sca <- prior
sca[sca<13]<-0
sca[sca>=13]<-1

r = sca

d=aggregate(r, fact=c(round(dim(r)[1]/dim(s)[1]),round(dim(r)[2]/dim(s)[2])), fun='mean') #fact equals r/s for cols and rows
e=resample(d, s,  method="ngb")


error = getValues(s)-getValues(e)

rms = rmse(error)
rms
cor(getValues(s),getValues(e), use='complete.obs')


#}
#t2=Sys.time()-t1
#t2

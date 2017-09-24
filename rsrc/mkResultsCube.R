#require(abind)
#Aggregatesensemble results in a 3 d matrix time*sample*ensemble
# two variBLE STILLL IN THERE: FILENAME, GRID NUMBER
wd="/home/joel/sim/ensembler2/"
#par=

ensemblePaths = list.files(wd, pattern= "ensemble")
nEnsem = length(ensemblePaths)
Nclust = length(list.files(paste0(wd,"ensemble0/grid1"), pattern= "S00*"))

rstStack=stack()
for (i in 1: nEnsem){ #python index

# ensemble loop here



resMat=c()
for (j in 1: Nclust){ 
	simindex=paste0('S',formatC(j, width=5,flag='0'))
	dat = read.table(paste0(wd,"ensemble",i-1,"/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
	resMat = cbind(resMat,dat$snow_water_equivalent.mm.)
	rst=raster(resMat)
}
rstStack=stack(rstStack, rst)
myarray = as.array(rstStack)
}


sample=5
mycols=rainbow(nEnsem)
plot(myarray[,sample,1],type='l', ylim=c(0,max(myarray[,sample,])),col=mycols[1],lwd=3)
for( i in 2:nEnsem){lines(myarray[,5,i],col=mycols[i],lwd=3)}




rstStack=stack()
for (i in 1: nEnsem){ #python index

# ensemble loop here



resMat=c()
for (j in 1: Nclust){ 
	simindex=paste0('S',formatC(j, width=5,flag='0'))
	dat = read.table(paste0(wd,"ensemble",i-1,"/grid1/", simindex,"/out/surface.txt"), sep=',', header=T)
	resMat = cbind(resMat,dat$snow_water_equivalent.mm.)
	rst=raster(resMat)
}
rstStack=stack(rstStack, rst)
myarray = as.array(rstStack)
}


sample=5
mycols=rainbow(nEnsem)
plot(myarray[,sample,1],type='l', ylim=c(0,max(myarray[,sample,])),col=mycols[1],lwd=3)
for( i in 2:nEnsem){lines(myarray[,5,i],col=mycols[i],lwd=3)}


# compute PBS at grid level

args = commandArgs(trailingOnly=TRUE)

DSTART=(args[1])
DEND=(args[2])
sdThresh=(args[3])

# ======== code ===================
# env
wd = "/home/joel/sim/ensembler_scale_sml/" #"/home/joel/sim/ensembler3/" #"/home/joel/sim/ensembler_scale_sml/" #"/home/joel/sim/ensembler_testRadflux/" #
priorwd = "/home/joel/sim/scale_test_sml/" #"/home/joel/sim/da_test2/"  #"/home/joel/sim/scale_test_sml/" #"/home/joel/sim/test_radflux/" #
grid=9 #2


# variables

# number of ensembles
nens <- 50 #50 #50

# R value for PBS algorithm
R <- 0.016

# number of tsub clusters
Nclust <- 150

# threshold for converting swe --> sca
#sdThresh <- 13

# cores used in parallel jobs
cores=6 # take this arg from config


# dependency
source("./rsrc/PBS.R") 
require(foreach)
require(doParallel)
require(raster) 

# readin
dem = raster(paste0(priorwd,"/predictors/ele.tif"))
landform = raster(paste0(wd,"ensemble0/grid",grid,"/landform.tif"))
rstack = brick(paste0(priorwd,"fsca_stack.tif"))
obsTS = read.csv(paste0(priorwd,"fsca_dates.csv"))


# total number of MODIS pixels
npix = ncell( rstack)


#===============================================================================
#	Construct results matrix
#===============================================================================

# retrieve results matrix: ensemble members * samples * timestampsd=strptime(obsTS$x, format='%Y-%m-%d')
d=strptime(obsTS$x, format='%Y-%m-%d')
d2=format(d, '%d/%m/%Y %H:%M')

dat = read.table(paste0(wd,"ensemble0/grid",grid,"/S00001/out/surface.txt"), sep=',', header=T)

# Extract timestamp corresponding to observation
obsIndex = which(dat$Date12.DDMMYYYYhhmm. %in% d2)

#convert obsTS to geotop time get index of results that fit obsTS
rstStack=stack()
for (i in 1: nens){ #python index

	resMat=c()
	for (j in 1: Nclust){ 
		simindex=paste0('S',formatC(j, width=5,flag='0'))
		dat = read.table(paste0(wd,"ensemble",i-1,"/grid",grid,"/", simindex,"/out/surface.txt"), sep=',', header=T)
				
		resMat = cbind(resMat,dat$snow_water_equivalent.mm.[obsIndex])
		rst=raster(resMat)
	}
rstStack=stack(rstStack, rst)
myarray = as.array(rstStack)
}

# convert swe > sdThresh to snowcover = TRUE/1
myarray[myarray<=sdThresh]<-0
myarray[myarray>sdThresh]<-1

# comput mean fSCA per sample
fsca.grid <- apply(myarray, FUN = "sum", MARGIN = c(1,3)) / 150

#compute mean grid fsca from mean sample fsca first to get around missing data issues




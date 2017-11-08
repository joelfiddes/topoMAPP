
 
# ======== code ===================

# env
wd = "/home/joel/sim/points_ensemble/" #"/home/joel/sim/ensembler3/" #"/home/joel/sim/ensembler_scale_sml/" #"/home/joel/sim/ensembler_testRadflux/" #
priorwd = "/home/joel/sim/points/" #"/home/joel/sim/da_test2/"  #"/home/joel/sim/scale_test_sml/" #"/home/joel/sim/test_radflux/" #
grid=9 #2


# variables

# number of ensembles
nens <- 50 #50 #50

# R value for PBS algorithm
R <- 0.016

# number of tsub clusters
Nclust <- 150

# threshold for converting swe --> sca
sdThresh <- 13

# cores used in parallel jobs
cores=6 # take this arg from config


# dependency
source("./rsrc/PBS.R") 
require(foreach)
require(doParallel)
require(raster) 

# readin
landform = raster(paste0(wd,"ensemble0/grid",grid,"/landform.tif"))
rstack = brick(paste0(priorwd,"fsca_stack.tif"))
obsTS = read.csv(paste0(priorwd,"fsca_dates.csv"))

# crop rstack to landform as landform represent grid and rstack the domain not necessarily the same
rstack = crop(rstack, landform)

# output
outfile = "wmat_mp.rd" #"wmat_trunc20.rd"
 
# pixel based timeseries 
pixTS = extract( rstack , 1:ncell(rstack) )

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


#===============================================================================
#	Run pixel calcs in parallel - can prob vectorise based on pix2samp
#===============================================================================

t1=Sys.time()
cl <- makeCluster(cores) # create a cluster with 2 cores
registerDoParallel(cl) # register the cluster



wmat = foreach(i = 1:npix, 
              .combine = "rbind",.packages = "raster") %dopar% {
              
   print(i)
	
	# Extract pixel based timesries of MODIS obs and scale
	obs = pixTS[i,] /100
	
	# get melt period
	vec=pixTS[i,]
	rvec=rev(vec)
	lastdata = which(rvec>0)[1] # last non-zero value
	lastdataindex = length(vec) - lastdata+1
	firstnodata = lastdataindex+1
	lastdateover95 = length(vec) - which (rvec >(max(rvec, na.rm=TRUE)*0.95))[1] # last date over 95% of max value accounts for max below 100%
	start=lastdateover95 
	end=firstnodata
	
	if(!is.na(start) & !is.na(end) & start >= end){
	start=200#lastdateover95 
	end=280#firstnodata
	}
	
	if(is.na(start)){
	start=200#lastdateover95 
	}
	
	if(is.na(end)){
	end=280#firstnodata
	}	
	
	# identify missing dates and reset start end index
	obsind = which(!is.na(obs)==TRUE)
	
	# cut to start end points (melt season )
	obsind <- obsind[obsind >= start & obsind <= end]
	
	# if less than two obs are present then PBS fails, this function steps forward though pixels already processed until at least 2 obs are found
	n=1
	while(length(obsind)<2){

	obs <- pixTS[i+n,] /100
	obsind <- which(!is.na(obs)==TRUE)
	obsind <- obsind[obsind >= start & obsind <= end]
	n<-n+1
	print(n)
	print(i+n)
	if(n > 20){
		start=200#lastdateover95 
	end=280#firstnodata
	next
	}
	
	# if algorithm, reaches last pixel search then goes backwards
		if ((i+n) == npix){
	
			n=1
			while(length(obsind)<2){

			obs <- pixTS[i-n,] /100
			obsind <- which(!is.na(obs)==T)
			obsind <- obsind[obsind >= start & obsind <= end]
			n<-n+1
			print(n)
			print(i-n)
	
			}
		}
	}

	# MODIS pixel,i mask
	singlecell = rasterFromCells(rstack[[1]], i, values=TRUE)
	
	# extract smallpix using mask
	smlPix = crop(landform, singlecell)
	
	# compute sample IDs that occur in MODIS pixel,i,  this is ragged and varies tri+-modally (sample of 4609) between eg.289, 272,256 (based on an experiment)
	sampids = values(smlPix) 

	
		#ensemble loop 
		# init HX
		HX = c()
		for ( j in 1 : nens){
	
		print(j)
		# number of smallpix in MODIS pixel
		#nsmlpix <- length(sampids)
		nsmlpix <- length(which(!is.na(sampids)==TRUE))

		
		# get unique sim ids 
		simindexs <- unique(sampids[!is.na(sampids)])
		
		# number of unique samples in pixel
		nSamp <- length(simindexs)
		
		# number of NA's in pixel
		nNA = length(which(is.na(sampids)==TRUE))

		# extract vector of each sample sca that occurs in pixel
		mat <- myarray[,simindexs,j]
		
		#mat <- mat[1:length(obs),] # this has to be replaced by correct date matching

		# count occurance of each in sample
		tab <- as.data.frame(table(sampids))
		tabmat <- t(mat)*tab$Freq
		
		# fSCA for pixel i and ensemble j
		fsca = colSums(tabmat)/nsmlpix
		
		# append to ensemble matrix
		HX= cbind(HX, fsca)

	}

	w=PBS(HX[obsind,],obs[obsind],R)
	#wmat = cbind(wmat,w)

}

t2=Sys.time()-t1

stopCluster(cl) # shut down the cluster

#write.csv(result, paste0(wd,"wmat.csv"))
save (wmat, file = paste0(wd,outfile))

print(paste0("PBSpixel run took: ", t2, " to process ", npix, " MODIS pixels"))



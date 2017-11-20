# dependency
source("./rsrc/PBS.R") 
require(foreach)
require(doParallel)
require(raster) 

args = commandArgs(trailingOnly=TRUE)
wd = args[1]
priorwd = args[2]
sca_wd = args[3]
grid = as.numeric(args[4])
nens = as.numeric(args[5])
Nclust = as.numeric(args[6])
sdThresh=as.numeric(args[7])
R=as.numeric(args[8])
cores = as.numeric(args[9])
DSTART = as.numeric(args[10])
DEND = as.numeric(args[11])
# ======== code ===================




# readin
landform = raster(paste0(priorwd,"/grid",grid,"/landform.tif"))
rstack = brick(paste0(sca_wd,"/fsca_stack.tif"))
obsTS = read.csv(paste0(sca_wd,"/fsca_dates.csv"))

# crop rstack to landform as landform represent grid and rstack the domain not necessarily the same
fscacrop = paste0(wd,"/fsca_crop.tif")
if(!file.exists(fscacrop)){
	rstack = crop(rstack, landform)
	writeRaster(rstack, fscacrop, overwrite=TRUE)
}else{
	rstack <- stack(fscacrop)
}

# read andwrite dates here
dates <- read.csv(paste0(sca_wd,"/fsca_dates.csv"))
write.csv(dates, paste0(wd,"/fsca_dates.csv"), row.names=FALSE)

# output
outfile1 = "wmat.rd" #"wmat_trunc20.rd" "HX.rd"#
outfile2 = "HX.rd"
# pixel based timeseries 
pixTS = extract( rstack , 1:ncell(rstack) )

# total number of MODIS pixels
npix = ncell( rstack)

#readin ensemble results matrix
load(paste0(wd, "/ensembRes.rd"))

# convert swe to sca
ensembRes[ensembRes<=sdThresh]<-0
ensembRes[ensembRes>sdThresh]<-1


#===============================================================================
#	Run pixel calcs in parallel - get WMAT need to combine wmat and HX calcs
#===============================================================================

t1=Sys.time()
cl <- makeCluster(cores) # create a cluster with 2 cores
registerDoParallel(cl) # register the cluster



wmat = foreach(i = 1:npix, .combine = "rbind",.packages = "raster") %dopar% {
              
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
	start=DSTART#lastdateover95 
	end=DEND#firstnodata
	}
	
	if(is.na(start)){
	start=DSTART#lastdateover95 
	}
	
	if(is.na(end)){
	end=DEND#firstnodata
	}	
	
	# set default here TRIAL
	#start = DSTART
	#end = DEND

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
		start=DSTART#lastdateover95 
	end=DEND#firstnodata
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
		mat <- ensembRes[,simindexs,j]
		
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
	#y=as.vector(HX)
	

}

t2=Sys.time()-t1

stopCluster(cl) # shut down the cluster

#write.csv(result, paste0(wd,"wmat.csv"))
save (wmat, file = paste0(wd,outfile1))

print(paste0("Weights calc took: ", t2, " to process ", npix, " MODIS pixels"))

#===============================================================================
#	Run pixel calcs in parallel - get HX
#===============================================================================

t1=Sys.time()
cl <- makeCluster(cores) # create a cluster with 2 cores
registerDoParallel(cl) # register the cluster



HX = foreach(i = 1:npix, .combine = "rbind",.packages = "raster") %dopar% {
              
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
	start=DSTART#lastdateover95 
	end=DEND#firstnodata
	}
	
	if(is.na(start)){
	start=DSTART#lastdateover95 
	}
	
	if(is.na(end)){
	end=DEND#firstnodata
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
		start=DSTART#lastdateover95 
	end=DEND#firstnodata
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
		mat <- ensembRes[,simindexs,j]
		
		#mat <- mat[1:length(obs),] # this has to be replaced by correct date matching

		# count occurance of each in sample
		tab <- as.data.frame(table(sampids))
		tabmat <- t(mat)*tab$Freq
		
		# fSCA for pixel i and ensemble j
		fsca = colSums(tabmat)/nsmlpix

		# append to ensemble matrix
		HX= cbind(HX, fsca)

	}

	
	y=as.vector(HX)
	

}

t2=Sys.time()-t1

stopCluster(cl) # shut down the cluster

#write.csv(result, paste0(wd,"wmat.csv"))
save (HX, file = paste0(wd,outfile2))

print(paste0("Weights calc took: ", t2, " to process ", npix, " MODIS pixels"))
		

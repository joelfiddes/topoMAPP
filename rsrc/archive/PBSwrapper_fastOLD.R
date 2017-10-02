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
require(plyr)
require(raster) 

# variables
nens=100
R=0.016
Nclust=150
sdThresh <- 0 # threshold for converting swe --> sca
wd = "/home/joel/sim/ensembler3/"
priorwd = "/home/joel/sim/da_test2/" 
cores=8
 


# readin
landform = raster(paste0(wd,"ensemble0/grid1/landform.tif"))
rstack = brick(paste0(priorwd,"fsca_stack.tif"))
obsTS = read.csv(paste0(priorwd,"fsca_dates.csv"))
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
myarray[myarray>sdThresh]<-1




wmat=c()
t1 <- Sys.time()
for (i in 1 : npix)
	{
	#print(i)
	
	# Extract pixel based timesries of MODIS obs and scale
	obs = pixTS[i,] /100
	
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
	
		
		# number of smallpix in MODIS pixel
		nsmlpix <- length(sampids)
		
		# get unique sim ids 
		simindexs <- unique(sampids[!is.na(sampids)])
		
		# number of unique samples in pixel
		nSamp <- length(simindexs)
		
		# number of NA's in pixel
		nNA = length(which(is.na(sampids)==TRUE))

		# extract vector of each sample swe that occurs in pixel, covert to SD.
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
	w=PBS(HX,obs,R)
	wmat = cbind(wmat,w)
	
}
t2 <- Sys.time() -t1
	print(t2)
write.csv(wmat, paste0(wd,"wmat.csv"))
# dim pix * ensemb


# compute mean w per samples
maxEns = apply(wmat, 2, max) 
plot(density(maxEns)) # bimodal distribution (approx means at 0.2 + 1)

# compute ensemble index of max weight per pixel
maxEns = apply(wmat, 2, which.max) 

# generate raster from vectorise
rst <- raster(matrix(maxEns, nrow= nrow(rstack), ncol=ncol(rstack))) # I dont see any topographical features in this, should I?

#dummy <- rstack[[1]]
#values(dummy) <- maxEns
#rst2 = resample(dummy, landform, method='ngb')

enscol_vec = c()
samplN_vec = c()
# assign max weight at MODIS pix to smlpix level
for (i in 1 : npix) {
print(i)
	# MODIS pixel,i mask
	singlecell = rasterFromCells(rstack[[1]], i, values=TRUE)
	
	# extract smallpix using mask
	smlPix = crop(landform, singlecell)
	
	# 
	nens <- maxEns[i]
	enscol = rep(nens, ncell(smlPix))
	samplN = getValues(smlPix)
	enscol_vec = c(enscol_vec, enscol)
	samplN_vec = c(samplN_vec,samplN)
        #df <- data.frame(samplN, enscol)
        #df_alt <- c(df_alt,df)
        }
	
df <- data.frame(samplN_vec, enscol_vec)
write.csv(df, paste0(wd,"df.csv"))
# Median/modal ensemble memeber per sample or take all ensembles and do weighted average of ppars per sample



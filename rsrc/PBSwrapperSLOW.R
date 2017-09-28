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
#matrix of w = 2500*100 [pix * ensemble]
#convert to rasterstack?
 
# ======== code ===================
t1 <- Sys.time()
# variables
nens=100
R=0.016
Nclust=50
 
require(raster) 

# readin
landform = raster("/home/joel/sim/ensembler2/ensemble0/grid1/landform.tif")
rstack = brick("/home/joel/sim/da_test/fsca_stack.tif")
obsTS = read.csv("/home/joel/sim/da_test/fsca_dates.csv")

# crop rstack to landform as landform represent grid and rstack the domain not necessarily the same

# pixel based timeseries 
pixTS = rasterToPoints( rstack )

# total number of MODIS pixels
npix = ncell( rstack )

#pixel loop
#npix_vec=c()


wmat=c()

for (i in 1 : npix)
	{
	print(i)
	
	# Extract pixel based timesries of MODIS obs
	y = pixTS[i,]
	
	# rm x/y coordinates from element 1:2
	obs = y[3: length(y)]

	
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
		
		#prepare results matrix
		
		
		# number of smallpix in MODIS pixel
		nsmlpix <- length(sampids)
		
		# get unique sim ids 
		simindexs=paste0('S',formatC(unique(sampids[!is.na(sampids)]), width=5,flag='0'))
		
		# number of unique samples in pixel
		nSamp = length(simindexs)
		
		# number of NA's in pixel
		nNA = length(which(is.na(sampids)==TRUE))

			# extract vector of each sample swe that occurs in pixel, covert to SD.
			mat=c()
			
			for (k in simindexs){
			
			dat = read.table(paste0("/home/joel/sim/ensembler2/ensemble0/grid1/",k,"/out/surface.txt"), sep=',', header=TRUE)
			var = dat$snow_water_equivalent.mm.
			
			# binary snow/no snow add buffer here?
			var[var>0]<-1
			
			mat=cbind(var,mat)
		}
			
		# count occurance of each in sample
		tab <- as.data.frame(table(sampids))
		tabmat <- t(mat)*tab$Freq
		fsca = colSums(tabmat)/nsmlpix
		HX= cbind(HX, fsca)

	}
	 #w=PBS(HX,obs,R)
	 w=obs
		wmat = cbind(wmat,w)
		t2 <- Sys.time() -t1
print(t2)
}



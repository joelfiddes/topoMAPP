# dependency
library("foreach")
library("doParallel")
require(raster) 

args = commandArgs(trailingOnly=TRUE)
wd = args[1]
priorwd = args[2]
grid = args[3]
nens = args[4]
Nclust = args[5]
sdThresh=(args[6])
R=args[7]
cores = args[8]
year=args[9]
 

# load files
load( paste0(wd,"wmat_",grid,year,".rd"))
rstack = brick(paste0(wd,"fsca_crop",grid,year,".tif"))
obsTS = read.csv(paste0(wd,"fsca_dates.csv"))
landform = raster(paste0(priorwd,"/grid",grid,"/landform.tif"))

#===============================================================================
#	Setup
#===============================================================================

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

sampleWeights=list()
for ( i in 1 : Nclust ){

# get vector of ensembles that exist in each sample
vec = ensem.vec[which(samp.vec==i)]

# get weights of each ensemble
ensemble_weights = table(vec)/length(vec)

# add to list
sampleWeights[[i]] <- ensemble_weights 

}

#list has Nclust items each with up to nens long (ragged)
save(sampleWeights, file = paste0(wd,"sampleWeights_",grid,".rd"))





	

#===============================================================================
#			compute modal swe
#===============================================================================

# 	we_mat=c()
#  	for ( i in 1:Nclust ){
# 	# vector of ensemble IDs
# 	ids = as.numeric(names(sampleWeights[[i]]))
	
# 	# vector of ensemble weights 
# 	weights = as.numeric((sampleWeights[[i]]))
# 	 #weights[ which.max(weights) ]<-1
# 	# weights[weights<1]<-0
# 	# multiply filtered timeseries for sample 1 and ensembles memebers "ids"

# 	medn <- ids[which.max(weights)]

# 	we <-  myarray_swe[,i,medn] 



# 	#if(!is.null(dim(we))){we = rowSums(we)}
# 	we_mat=cbind(we_mat, we) # time * samples weighted 
 
#  }



# #===============================================================================
# #			compute modal sca
# #===============================================================================

# 	we_mat_sca=c()
#  	for ( i in 1:Nclust ){
# 	# vector of ensemble IDs
# 	ids = as.numeric(names(sampleWeights[[i]]))
	
# 	# vector of ensemble weights 
# 	weights = as.numeric((sampleWeights[[i]]))
# 	 #weights[ which.max(weights) ]<-1
# 	# weights[weights<1]<-0
# 	# multiply filtered timeseries for sample 1 and ensembles memebers "ids"

# 	medn <- ids[which.max(weights)]

# 	we <-  myarray[,i,medn] 



# 	#if(!is.null(dim(we))){we = rowSums(we)}
# 	we_mat_sca=cbind(we_mat_sca, we) # time * samples weighted 
 
#  }
 





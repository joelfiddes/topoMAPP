# Description of DA scheme
Hi Kris :)
## Nomenclature

SAMP = toposub sample
PIX = MODIS pixel
FGRID =  fine grid DEM
ENS = ensemble
T = time
NDSI = Normalised Difference Snow Index
fSCA = fractional snow covered area
AOI = area of interest
N = number of (prefix)
[] = dimensions

## Formula
```
w=PBS(HX,obs,R)

Where:
HX = matrix [SAMP * ENS]
OBS = vector of observations 1*T
R = scalar bayes parameter (0.016)
w = weights [1*ENS]
```

## Postprocess MODIS SCA products
- IN: downloaded MODIS SCA 
- convert NDSI to fSCA
- OUT: rstack of fSCA [AOI * T]

## PBS - get weights
- IN: rstack
- compute sim results matrix MYARRAY [ENS * SAMP * T]
- convert sim SWE to SCA
- Extract OBS per PIX [1* 365]
- construct HX from sim results represented in PIX [SAMP * ENS]
- compute W using PBS
- OUT: matrix of weights, WMAT [ENS * PIX ]

```
PIX loop, i:
	-- PIX timeseries [1*365]
	-- Find melt period (last date over 95% : last non-zero)
	-- sampids = values(smlPix) # compute sample IDs that occur in MODIS pixel,i,  this is ragged and varies tri+-modally (sample of 4609) between eg.289, 272,256 (based on an experiment)
	
	ENS loop , j: (make HX for pixel i)
		-- simindexs <- unique(sampids[!is.na(sampids)]) # get unique sim ids 
		-- mat <- myarray[,simindexs,j] # extract vector of each sample sca that occurs in pixel
		-- tab <- as.data.frame(table(sampids))  # count occurance of each in sample
		-- tabmat <- t(mat)*tab$Freq
		-- fsca = colSums(tabmat)/nsmlpix  # weighted average fSCA for pixel i and ensemble j
		-- HX= cbind(HX, fsca)  # append to ensemble matrix

	w=PBS(HX[obsind,],obs[obsind],R) # run PBS indexed by non NA OBS in pixel timeseries

wmat = cbind(wmat,w)  
		
```

## DA - compute posterior
- IN: wmat , MYARRAY 

Allocated max weighted ensembel memebers per MODIS pixel and dissaggregate to FGRID. Can now map SAMP ID to max(ENS) per FGRID pixel.

```
# compute max weighted ensemble memebr per pixel, RST [AOI grid, 500m]

# compute ensemble index of max weight per pixel
ID.max.weight = apply(wmat, 1, which.max) 

# make raster container
rst <- rstack[[1]]

# fill with values ensemble ID
rst = setValues(rst, as.numeric(ID.max.weight))

# disaggregate to FGRID [AOI grid, 30m]
d=disaggregate(s, fact=c(round(dim(r)[1]/dim(s)[1]),round(dim(r)[2]/dim(s)[2])), method='') #fact equals r/s for cols and rows
e=resample(d, r,  method="ngb")

# vectorise FGRIDS
ensem.vec = as.vector(e) # ID ensemble of max weights
samp.vec = as.vector(r) # ID of SAMP
```

Compute for each toposub sample, SAMP unique occurances of EnSEMBLEs. Make vector of this (variable length, max N_ENS)

```
SAMP loop [1:N_SAMP]:
	# get vector of ensembles that exist in each sample
	vec = ensem.vec[which(samp.vec==i)]

	# get weights of each ensemble
	ensemble_weights = table(vec)/length(vec)

	# write to list
	mylist[[i]] <- ensemble_weights 

save(mylist, file = paste0(wd,"mylist.rd"))

```
Convert SWE to SCA with sdThresh = 13 mm

```
myarray[myarray<=sdThresh]<-0
myarray[myarray>sdThresh]<-1
```
Compute posterior median and quantiles (not shown)
```
## posterior median

id=samples[j] # val location

sample= id
ndays = length(myarray_swe[ , 1, 1]) # time index

median.vec = c()
for ( i in 1: ndays){
	mu = myarray_swe[ i, sample, ] #prior value indexed by time and sample
	w = mylist[[ sample ]] # weights of sample

	# fill missing ensemble weights with 0, some ensemble memebers do not exist in a sample
	index = as.numeric(names(mylist[[ sample ]]))
	df=data.frame(index,w)
	df.new = data.frame(index = 1:nens)
	df.fill = merge(df.new,df, all.x = TRUE)
	wfill=df.fill$Freq
	wfill[which(is.na(wfill))]<-0


	df = data.frame(mu, wfill ) # dataframe of weights , sample ids
	dfOrder =  df[ with(df, order(mu)), ] # order
	med = approx( cumsum(dfOrder$wfill),dfOrder$mu , xout=0.5) # linear interpolation at 50%
	median.vec = c(median.vec, med$y)
	}
```
repeat with xout=0.05 and xout=0.95 for quantiles. 

## DA - compute prior
Prior is computed with ensembele memeber all equally weighted

```
# MEDIAN
id=samples[j]

sample= id
ndays = length(myarray_swe[ , 1, 1])

median.prior = c()
for ( i in 1: ndays){

mu = myarray_swe[ i, sample, ]
w = rep((1/nens),nens)

df = data.frame(mu, w )
dfOrder =  df[ with(df, order(mu)), ]
#plot(dfOrder$mu , cumsum(dfOrder$wfill))
#df2 = data.frame(dfOrder$mu , cumsum(dfOrder$Freq))
med = approx( cumsum(dfOrder$w),dfOrder$mu , xout=0.5)
median.prior = c(median.prior, med$y)
}
```
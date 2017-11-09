# Description of DA scheme

## Nomenclature
SAMP = toposub sample
PIX = MODIS pixel
FGRID =  fine grid DEM
ENS = ensemble
T = time
NDSI = 
fSCA = fractional snow covered area
AOI = area of interest
N = number of (prefix)
[] = dimensions

## Formula
```
w=PBS(HX,obs,R)
```
*Where: *
HX = matrix [SAMP * ENS]
OBS = vector of observations 1*T
R = scalar bayes parameter (0.016)
w = weights [1*ENS]

## Postprocess MODIS SCA products
- IN: downloaded MODIS SCA 
- convert NDSI to fSCA
- OUT: rstack of fSCA [AOI * T]

## PBS - get weights
- IN: rstack
- compute sim results matrix [ENS * SAMP * T]
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
- 
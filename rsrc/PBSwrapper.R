#in:
# tObs=vector timestamps of obs, size = No*1 [16]
# rstObs=raster stack of obs covering domain = No*MODpix^2 [16*50*50]

# need inverse of landform (each smlPix has cluster id), overlay bigPix grid on 
# smlPix grid, extract sample IDs per pixel (could be ragged dataframe for geolocation issues)
read in landform
read in MODIS grid
R=0.016

# 
pixelloop i in 1:n:
	- extract sampids for bigPix[i]
	- compute fSCAObs per pixel using sampids (Y=16*1)	
	ensemble loop j in 1:n:
		- compute fSCATsub per pixel[i] for each ensemble[j] (HX=16*100)
		end	
	- w=PBS(HX,Y,R)
	- save w (100)
	end
# out:	
matrix of w = 2500*100 [pix * ensemble]
convert to rasterstack?
 
 # code
 
 require(raster)
 landform = raster("/home/joel/sim/ensembler/ensemble0/grid1/landform.tif")
 rstack = raster("/home/joel/sim/topomap_points/fsca_stack.tif")
# crop rstack to landform as landform represent grid and rstacj=k the domain not necessarily the same

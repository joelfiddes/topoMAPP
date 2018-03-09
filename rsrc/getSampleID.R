# takes landform and spatial points (fullpath) as input and returns Sample IDS

#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)

#SOURCE
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
points=args[2]
rst=args[3] # "fsca_stack.tif"

lf= raster(paste0(wd,"/landform.tif"))
shp = shapefile(points)
#IDS = extract(lf, shp)
IDS = na.omit(extract(lf, shp))
#long = formatC(IDS, flag="0", width=5)
#paths = paste0(wd,"/S",long)
cat((paths))
 
rstack = brick(rst)
rstack = crop(rstack, lf)
rtest <- rstack[[1]]
values(rtest) <- 1: ncell(rtest)

# index of modis pixels containing val points
npix = sort(na.omit(extract(rtest, shp)))

# loop thgrough pixels

idVec= c()
for ( i in npix ) {
# MODIS pixel,i mask
singlecell = rasterFromCells(rstack[[1]], i, values = TRUE)

 # extract smallpix using mask
smlPix = crop(lf, singlecell)

# IDs of sims contained in Modis pixel (around 324, can vary a bit)
sampids = values(smlPix)
id =  unique(sampids)
idVec = c(idVec, id)
}

long = formatC(idVec, flag="0", width=5)
paths = paste0(wd,"/S",long)
cat((paths))
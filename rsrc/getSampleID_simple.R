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
lf=args[1]
points=args[2]


lf= raster(lf)
shp = shapefile(points)

id = extract(lf, shp)
key = shp[[1]]
df= data.frame(id,key)
print(df)

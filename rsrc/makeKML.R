
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
file=args[2]
outFormat=args[3]
outPath=args[4]

require(raster)
require(plotKML)
r=raster(file)
e=extent(r)
p = as(e, 'SpatialPolygons')
projection(p) <- CRS("+init=epsg:4326")

 #shapefile(p, '/home/joel/sim/topomap_test/predictors/extent.shp')
if (outFormat=='shape'){kml(obj=p,  file=paste0(outPath,'.kml'))}
if (outFormat=='raster'){KML(x=r, filename=paste0(outPath,'.kmz'), col=rev(terrain.colors(255)),  colNA=NA, maxpixels=10000,blur=1, overwrite=TRUE)}


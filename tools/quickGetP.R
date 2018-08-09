require(ncdf4)
require(raster)
file = "tp_5_tj_10.nc"

nc = nc_open(file)
tp =ncvar_get(nc ,"tp")
a =apply(tp, FUN = "sum", c(1,2))

r=raster(t(a))
r2 = raster(file)

extent(r) <- extent(r2)
#l1 = stack("tp_int.nc")
#l2 = stack("tp_5.nc")
#l3 = stack("tp_5_10.nc")

#l1s = sum(l1)
#l2s = sum(l2)
#L3S= sum(l3)
shp = shapefile("/home/joel/gdrive/Projects/TAJIK_SNOW/data/spatial/TJK_adm1.sh")
plot(r*1000)
plot(shp, add=T)

#trmm = raster("/home/joel/gdrive/Projects/TAJIK_SNOW/data/climate/trmmMean.tif")






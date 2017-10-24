require(raster)
ex = raster('/home/joel/sim/test_radflux/spatial/eraExtent.tif')
rst = raster("/home/joel/sim/test_radflux/eraDat/PLEVEL.nc")
values(rst) <- 1:ncell(rst)
n = crop(rst,ex)
getValues(n)


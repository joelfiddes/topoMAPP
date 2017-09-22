wd='/home/joel/sim/topomap_points/'
setwd(wd)
modfiles=list.files(pattern='surface.txt', recursive=T)

#match ids to results
lp=list.files(pattern='listpoints.txt', recursive=T)
lp=list.files(pattern='^grid/listpoints.txt', recursive=T)







modDat='/home/joel/sim/topomap_points/grid9/S00003/out/surface.txt'
valDat='/home/joel/data/GCOS/sp_5WJ.txt'

mod = read.csv(modDat)
val = read.csv(valDat)

mod.time = strptime(mod$Date12.DDMMYYYYhhmm., format='%d/%m/%Y')
val.time = strptime(val$DATUM, format='%d.%m.%Y')

mod.swe = mod$snow_water_equivalent.mm.
mod.sd = mod$snow_depth.mm.

val.swe = val$SWE.mm.
val.sd = val$HS.cm. 

mod$time <- mod.time
val$time <- val.time

require(xts)
mod.xts = xts(mod, order.by = mod$time)
val.xts = xts(val, order.by = val$time)

xtd <- merge(mod.xts, val.xts, all=TRUE)

plot(xtd$snow_water_equivalent.mm. ,xlim=(xlim=as.POSIXct(c("2008-09-01 00:00:00","2009-09-01 03:00:00"))))
points(xtd$SWE.mm., xlim=(xlim=as.POSIXct(c("2008-09-01 00:00:00","2009-09-01 03:00:00"))))


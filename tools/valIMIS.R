# assume sim dates are a subset of valdates
# sim is daily
# plot entirety of sim dates

require(raster)
require(hydroGOF)
station = "WFJ_2"
file="surface.txt"
badstations=c("ELA_3", "LAV_1")
goodStations = c("DAV_1", "DAV_2" ,"DAV_3" ,"DAV_4" ,"DAV_5", "FLU_2" ,"KLO_1", "KLO_2", "KLO_3" ,"PAR_2", "SLF_2", "WFJ_1" ,"WFJ_2")

imisdir = "/home/joel/mnt/myserver/nas/data/imis/data/montblanc"
wd = "/home/joel/mnt/myserver/sim/wfj_era5/grid1"
wd = "/home/joel/mnt/myserver/sim/wfj_interim2/grid1"
wd="/home/joel/mnt/myserver/nas/sim/SIMS_JAN18/gcos_cor/grid1"
shp = shapefile("/home/joel/mnt/myserver/nas/data/imis/gis/IMISkoordinaten.shp")
map = raster(paste0(wd, "/predictors/ele.tif"))
lf=raster(paste0(wd, '/landform.tif'))
#plot(map)
#plot(shp, add=T)


dem = raster(paste0(wd, "/predictors/ele.tif"))
options("scipen" = 14)

# stations that exist in domain
stationsInDomain = crop(shp, lf)

modvec=c()
valvec=c()

pdf("/home/joel/Documents/manuscripts/da/plots/era5v2_sd.pdf", width=14, height=14)
par(mfrow=c(4,4))
for (stat in stationsInDomain$Name){

station = paste0(substring(stat,1,3),"_", substring(stat, 4) )
# remove "_" so can read shapefile ID format
metadataName = gsub("_", "", station)

print(station)

#if (station %in% badstations){print(paste0("skipping ", station));next}
if (!(station %in% goodStations)){print(paste0("skipping ", station));next}
# get index
shpID = which(shp$Name==metadataName)

# extract sample number
sampID = extract(lf, shp[shpID,])
sampID = formatC(sampID, width=5, flag="0")

# elevation
ele = extract(dem, shp[shpID,])

# read in sample
simDat = read.csv(paste0(wd,"/S", sampID, "/out/", file ))

# get start date
start = simDat$Date12.DDMMYYYYhhmm.[1]
end = simDat$Date12.DDMMYYYYhhmm.[length(simDat$Date12.DDMMYYYYhhmm.)]
#as.Date(simDat$Date12.DDMMYYYYhhmm.,format="%Y/%m/%d H:m")



# get val data
# retrieve data
valfile=paste0(imisdir,"/",station,".csv")
if (file.exists(valfile)){	dat = read.csv(valfile, header=F)} else{print(paste0("file not found: ", station)) ; next}

dat = read.csv(paste0(imisdir,"/",station,".csv"), header=F)
dat[dat< -100] <-NA


dailyAgg = substring(dat$V3, 1,8)
val.daily = aggregate(dat$V4,list(dailyAgg), FUN="mean")
#as.Date(val.daily$Group.1, format=%Y%m%d )

# get mod and val indexes
startMod = which(simDat$Date12.DDMMYYYYhhmm.== start)
endMod = which(simDat$Date12.DDMMYYYYhhmm. == end)
	
valStart = paste0(substring(start,7,10),substring(start,4,5), substring(start,1,2))
valEnd= paste0(substring(end,7,10),substring(end,4,5), substring(end,1,2))
	
startVal= which(val.daily$Group.1 == valStart)
endVal = which(val.daily$Group.1 == valEnd)
	
# plots	

ymax = max(c(simDat$snow_depth.mm.[startMod: endMod]/10, val.daily$x[startVal:endVal]), na.rm=T)
rms = rmse(simDat$snow_depth.mm.[startMod: endMod]/10, val.daily$x[startVal:endVal] )

plot(simDat$snow_depth.mm.[startMod: endMod]/10,ylim=c(0, ymax),lwd=3 , type="l", main=paste(station,"samp=",sampID," ele="  ,ele, "rmse=",round(rms,2)))

lines(val.daily$x[startVal:endVal], col='green', lwd=2)
legend("topright", c("obs", "mod") , col = c("green", "black"), lwd=3)

modvec=c(modvec,simDat$snow_depth.mm.[startMod: endMod]/10)
valvec=c(valvec, val.daily$x[startVal:endVal])
}

rms = rmse(modvec, valvec)
plot(modvec, valvec, main = paste("rmse=", round(rms,2)))
abline(0,1)

dev.off()



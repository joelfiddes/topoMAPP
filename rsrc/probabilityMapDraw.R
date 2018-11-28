# run toposub_post_2_prob.R first

require(raster)
require(viridis)

prob = raster("/home/joel/mnt/myserver/sim/yala_interim_ensemble/probabitiyPfmap.tif")
open = raster("/home/joel/mnt/myserver/sim/yala_interim/grid1/crisp_X100.000000_150.tif ")
shpnew = shapefile("/home/joel/gdrive/Projects/SEED2016/DATA/new_loggers/spatialdata/geoprecisionloggerpositions_master.csv.shp")
shpold = shapefile("~/gdrive/Projects/SEED2016/DATA/marcols_loggers/positions.csv.shp")


 prob = raster("/home/joel/mnt/myserver/sim/yala_interim_ensemble/probabitiyPfmap.tif")
 open = raster("/home/joel/mnt/myserver/sim/yala_interim/grid1/crisp_X100.000000_150.tif")
 shpnew = shapefile("/home/joel/gdrive/Projects/SEED2016/DATA/new_loggers/spatialdata/geoprecisionloggerpositions_master.csv.shp")
 shpold = shapefile("~/gdrive/Projects/SEED2016/DATA/marcols_loggers/positions.csv.shp")


 open = raster("/home/joel/mnt/myserver/sim/yala_interim/grid1/crisp_X100.000000_150.tif ")
 

 png("val.png", width = 3200, height=2200)
par(mfrow=c(1,2))
par(mar=c(20.1,16.1,20.1,24.1))
 open[open>=0]<- NA
 #open[open>=0]<- 1
 #open[open<0 & open>= -2]<- -1
 #open[open< -2]<- -2

 plot(open, xlim=c(85.6,85.64), ylim=c(28.2,28.26), col=viridis(20),legend=F, main="open-loop", cex.main=7)

 plot(open, legend.only=TRUE, col=viridis(20), legend.width=5, legend.shrink=1,legend.args=list(text='MAGST (C)', side=4, font=2, line=8, cex=3), axis.args=list(cex.axis=4))


 breaks = c(-30, -2, 0, 30)
 colors = c("blue", "green ", "red")


 plot(shpold, col=colors[cut(shpold$magst, breaks)],add=T, pch=2, lwd=8, cex=8)
 plot(shpnew, col=colors[cut(shpnew$magst, breaks)],add=T, pch=2, lwd=8, cex=8)
legend("topright", pch=2 ,col=c("blue", "green", "red"), c("cold","warm", "none"), cex=5, lwd=8)



 prob[prob<50]<- NA
 #open[open>=0]<- 1
 #open[open<0 & open>= -2]<- -1
 #open[open< -2]<- -2

 plot(prob, xlim=c(85.6,85.64), ylim=c(28.2,28.26), col=rev(viridis(20)), legend=F, main="100 member ensemble", cex.main=7)
 plot(prob, legend.only=TRUE, col=rev(viridis(20)), legend.width=5, legend.shrink=1,legend.args=list(text='PF probability', side=4, font=2, line=8, cex=3), axis.args=list(cex.axis=4))

 breaks = c(-30, -2, 0, 30)
 colors = c("blue", "green ", "red")


 plot(shpold, col=colors[cut(shpold$magst, breaks)],add=T, pch=2, lwd=8, cex=8)
 plot(shpnew, col=colors[cut(shpnew$magst, breaks)],add=T, pch=2, lwd=8, cex=8)
legend("topright", pch=2 ,col=c("blue", "green", "red"), c("cold","warm", "none"), cex=5, lwd=8)
dev.off()

















f=list.files(pattern="^crisp", recursive=T)

# loop scales better
for ( i in 1:length(f)){
brk = raster(f[i])
rc <- matrix(c(-100,0,1,0,100,0), ncol=3, byrow=TRUE)
rbrk = reclassify(brk, rc)
#brk[brk<=0]<- 0
#brk[brk>0]<- 1
writeRaster(rbrk, paste0("./pf", i, ".tif"))
}
f2=list.files(pattern="^pf", recursive=F)
rbrk = stack(f2)
sbrk = sum(rbrk, na.rm=T)
prob = sbrk/nlayers(rbrk)
plot(prob, col=rev(inferno(20)))

ext = extent(85.6, 85.8,28.1, 28.3)
probcrop = crop(prob,ext)
plot(probcrop)

KML(x=probcrop, filename='probPFcrop.kml', col=rev(inferno(20)), overwrite=T, maxpixels=2000000)
writeRaster(probPFcrop,"probPFcrop.tif" )


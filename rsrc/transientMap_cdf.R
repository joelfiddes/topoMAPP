require(raster)
gridpath = "/home/joel/sim/yala_interim_long/grid1/"
lf = list.files(gridpath, "^crisp_X100")


pixPeVec = c()
pixPewVec = c()
pixPecVec = c()

for ( f in lf ){

rst = raster(f)
print(f)
# total
pe = rst
pe[pe>0]<-NA
pe[pe<1000]<-1
pixPe = cellStats(pe, "sum")


# warm
pew = rst
pew[pew>0]<-NA
pew[pew < -2]<-NA
pew[pew< 1000]<-1
pixPew = cellStats(pew, "sum")

# cold
pec = rst
pec[pec> -2]<-NA
pec[pec< 1000]<-1
pixPec = cellStats(pec, "sum")

pixPeVec = c(pixPeVec, pixPe)
pixPewVec = c(pixPewVec,pixPew)
pixPecVec = c(pixPecVec ,pixPec )
}


#r = projectRaster(rst, crs="+proj=utm +zone=45 +ellps=WGS84 +datum=WGS84 +units=m +no_defs ")

cellsize = 837.76 # sqm 27.2* 30.8

year= seq(1979,2016,1)
mymin = (min(c(pixPeVec,pixPecVec,pixPewVec),na.rm=T)*cellsize)  /10^6
 mymax = (max(c(pixPeVec,pixPecVec,pixPewVec),na.rm=T)*cellsize)  /10^6 



 peA = (pixPeVec*cellsize)/1000000 
 pewA = (pixPewVec*cellsize)/1000000 
 pecA = (pixPecVec*cellsize)/1000000 
plot(year,peA,type="l" ,lwd=3, ylim=c( mymin,mymax  ) )
lines(year,pecA,col="blue" ,lwd=3)
 lines(year,pewA,col="red" ,lwd=3)

 abline(lm(peA~ year),  lty=5)
 abline(lm(pecA~ year), lty=5)
 abline(lm(pewA~ year),  lty=5)




plot(r, col=topo.colors(100), legend=FALSE, axes=FALSE)
r.range <- c(minValue(r), maxValue(r))
plot(r, legend.only=TRUE, col=topo.colors(100),
     legend.width=1, legend.shrink=0.75,
     axis.args=list(at=seq(r.range[1], r.range[2], 25),
                    labels=seq(r.range[1], r.range[2], 25), 
                    cex.axis=0.6),
     legend.args=list(text='Elevation (m)', side=4, font=2, line=2.5, cex=0.8))





png("trans4.png", width = 4800, height=2200)
require(viridis)
par(mfrow=c(1,2))
par(mar=c(20.1,16.1,20.1,24.1))
shp = shapefile("/home/joel/nas/data/shapefiles/woeldboundaries/worldL1.shp")
r=raster(lf[6])
r[r>0]<-NA
plot(r, col=inferno(100),zlim=c(-20,0), main = "1985", legend =F,cex.main=7)
plot(shp,add=T, lwd=5)
text(x=85.2 ,y=28.2, labels="Nepal", cex=5)
text(x=85.8 ,y=28.8, labels="Tibet",cex=5)
#https://stackoverflow.com/questions/9436947/legend-properties-when-legend-only-t-raster-package
plot(r, legend.only=TRUE, col=inferno(20), legend.width=5, legend.shrink=1,legend.args=list(text='MAGST (C)', side=4, font=2, line=8, cex=3),axis.args=list(
                    cex.axis=4), zlim=c(-20,0))
#title(main="1985", col.main="black", cex.main=7)
# axis.args=list(at=seq(r.range[1], r.range[2], 25),  labels=seq(r.range[1], r.range[2], 25),   cex.axis=0.6),

r=raster(lf[38])
r[r>0]<-NA
plot(r, col=inferno(20), main="2016", legend =F,cex.main=7)
plot(r, legend.only=TRUE, col=inferno(100), legend.width=5, legend.shrink=1,legend.args=list(text='MAGST (C)', side=4, font=2, line=8, cex=3), axis.args=list(
                    cex.axis=4),zlim=c(-20,0))
text(x=85.2 ,y=28.2, labels="Nepal",cex=5)
text(x=85.8 ,y=28.8, labels="Tibet",cex=5)
plot(shp,add=T, lwd=5)
#title(main="2016",  cex.main=7)
dev.off()
 peA = (pixPeVec*cellsize)/1000000 
 pewA = (pixPewVec*cellsize)/1000000 
 pecA = (pixPecVec*cellsize)/1000000 
syear=6
eyear=38

png("trendPf.png", width = 600, height=600)
plot(year[syear:eyear],peA[syear:eyear],type="l" ,lwd=3, ylim=c( mymin,mymax  ) , ylab="Area (Sq. Km)", xlab="Years", main = "MAGST extent", cex.axis=1)
legend("bottomleft", c("Total extent (< 0°C)", "warm (0 - -2°C)", "cold (< -2°C)"), col=c("black", "red", "blue"), lwd=6, lty=1 , cex=1)
lines(year[syear:eyear],pecA[syear:eyear],col="blue" ,lwd=3)
lines(year[syear:eyear],pewA[syear:eyear],col="red" ,lwd=3)
#title(main="MAGST extent", col.main="black",xlab="Years", ylab="Area (sq. km)", cex.lab=1, cex.main=1)
abline(lm(peA[syear:eyear]~ year[syear:eyear]),  lty=5)
abline(lm(pecA[syear:eyear]~ year[syear:eyear]), lty=5)
abline(lm(pewA[syear:eyear]~ year[syear:eyear]),  lty=5)

#title(xlab="Years", line=5, cex.lab=4, family="Calibri Light")

dev.off()




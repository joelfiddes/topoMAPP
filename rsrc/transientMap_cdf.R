require(raster)
gridpath = "/home/joel/sim/yala_interim_long/grid1/"
lf = list.files(gridpath, "^crisp")


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


r = projectRaster(rst, crs="+proj=utm +zone=45 +ellps=WGS84 +datum=WGS84 +units=m +no_defs ")
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

require(viridis)
par(mfrow=c(1,3))

r=raster(lf[6])
r[r>0]<-NA
plot(r, col=inferno(20),zlim=c(-20,0))

r=raster(lf[36])
r[r>0]<-NA
plot(r, col=inferno(20), zlim=c(-20,0))

 peA = (pixPeVec*cellsize)/1000000 
 pewA = (pixPewVec*cellsize)/1000000 
 pecA = (pixPecVec*cellsize)/1000000 
syear=6
eyear=36
plot(year[syear:eyear],peA[syear:eyear],type="l" ,lwd=3, ylim=c( mymin,mymax  ) , ylab="Square Km")
lines(year[syear:eyear],pecA[syear:eyear],col="blue" ,lwd=3)
lines(year[syear:eyear],pewA[syear:eyear],col="red" ,lwd=3)

abline(lm(peA[syear:eyear]~ year[syear:eyear]),  lty=5)
abline(lm(pecA[syear:eyear]~ year[syear:eyear]), lty=5)
abline(lm(pewA[syear:eyear]~ year[syear:eyear]),  lty=5)


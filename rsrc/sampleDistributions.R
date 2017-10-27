args = commandArgs(trailingOnly=TRUE)
gridpath=args[1]
svfCompute=args[2]
outName=args[3]

require(raster)

predDir=paste0(gridpath, "/predictors")
lsp=read.csv(paste0(gridpath, "/listpoints.txt"))
pdf(paste0(gridpath, '/', outName), width=6, height =16)
par(mfrow=c(4,1))
if (svfCompute ==TRUE){par(mfrow=c(5,1))}


# elevation
myhist = hist(lsp$ele, plot=FALSE)
topo=raster(paste0(predDir, "/ele.tif"))
myd = density(topo, plot=FALSE)
multiplier = myhist$counts / myhist$density
myd$y = myd$y*multiplier[1]
maxlim = max(c(max(myhist$breaks),max(myd$x)))
minlim = min(c(min(myhist$breaks),min(myd$x)))
plot(myhist, xlim=c(minlim,maxlim))
lines(myd, lwd=3, col='green')
legend("topright", c("density of finegrid"), col='green', lty=1, lwd=3)


# asp
myhist = hist(lsp$asp, plot=FALSE)
topo=raster(paste0(predDir, "/asp.tif"))
myd = density(topo, plot=FALSE)

multiplier = myhist$counts / myhist$density
myd$y = myd$y*multiplier[1]
maxlim = max(c(max(myhist$breaks),max(myd$x)))
minlim = min(c(min(myhist$breaks),min(myd$x)))
plot(myhist, xlim=c(minlim,maxlim))
lines(myd, lwd=3, col='green')
legend("topright", c("density of finegrid"), col='green', lty=1, lwd=3)


# slp
myhist = hist(lsp$slp, plot=FALSE)
topo=raster(paste0(predDir, "/slp.tif"))
myd = density(topo, plot=FALSE)

multiplier = myhist$counts / myhist$density
myd$y = myd$y*multiplier[1]
maxlim = max(c(max(myhist$breaks),max(myd$x)))
minlim = min(c(min(myhist$breaks),min(myd$x)))
plot(myhist, xlim=c(minlim,maxlim))
lines(myd, lwd=3, col='green')
legend("topright", c("density of finegrid"), col='green', lty=1, lwd=3)


if (svfCompute ==TRUE){
# svf
myhist = hist(lsp$svf, plot=FALSE)
topo=raster(paste0(predDir, "/svf.tif"))
myd = density(topo, plot=FALSE)

multiplier = myhist$counts / myhist$density
myd$y = myd$y*multiplier[1]
maxlim = max(c(max(myhist$breaks),max(myd$x)))
minlim = min(c(min(myhist$breaks),min(myd$x)))
plot(myhist, xlim=c(minlim,maxlim))
lines(myd, lwd=3, col='green')
legend("topright", c("density of finegrid"), col='green', lty=1, lwd=3)

}

hist(lsp$members)
dev.off()
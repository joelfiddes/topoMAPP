# run toposub_post_2_prob.R first

require(raster)
require(viridis)
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


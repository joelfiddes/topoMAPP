
setwd(wd)

# val data = lon, lat, magst
# find which sample locations belong to
# extract mean values for that samåple
# compare


require(raster)
require(rgeos)
require(ncdf)

gst=read.table('/home/joel/data/permos/magstAll.txt', sep=',', header=T)
site=read.table('/home/joel/data/permos/sites.txt', sep=',', header=T)
#rst=raster('/home/joel/src/hobbes/results3/b14/fuzRst2_X100.000000.tif')
#shp=shapefile('/home/joel/data/shapefiles/gstSite_UTM.shp')

#eliminate partial years
gstsub=subset(gst, gst$Count>350, 1:6)
#eliminate years outside time slice
#gstsub=subset(gstsub1, gstsub1$Year>2006 & gstsub1$Year<2011, 1:6)
#years per site
idvec=unique(gstsub$GSTSite_ID)

nvec=c()
for (i in idvec){
which(gstsub$GSTSite_ID==i)
n=length(which(gstsub$GSTSite_ID==i))
nvec=c(nvec,n)
}

#aggregate by year
gstagg=aggregate(gstsub$Temp, by=list(gstsub$GSTSite_ID), FUN=mean)

#one year
gst2009==subset(gstsub, gstsub$Year=2009, 1:6)

df=c()
site$perID 
for (i in 1:length(gst2009$GSTSite_ID ))
	{
	siteIndex=which(site$perID==gst2009$GSTSite_ID[i] )
	lon=site$Lon[siteIndex]
	lat=site$Lat[siteIndex]
	surfType=site$SurfType[siteIndex]
	df=rbind(df, c(lon, lat, surfType))
	}


valdat=cbind(gst2009, df)
names(valdat) <- c('GSTSite_ID', 'Year'   ,  'Temp'    ,  'Tmin'   ,  'Tmax' ,'Count'  ,  'lon', 'lat', 'surfType')
write.table(valdat, 'valData2009.txt', sep=',', row.names=FALSE)
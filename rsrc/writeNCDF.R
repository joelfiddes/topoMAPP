# create and write the netCDF file -- ncdf4 version
library(ncdf4)

# try to remove lat an change lon to samples
nclust=150
# define dimensions
londim <- ncdim_def("lon","degrees_east",1:nclust) 
latdim <- ncdim_def("lat","degrees_north",rep(1,nclust)) 

tunits <- "days since 1900-01-01 00:00:00.0 -0:00"
t3 = 
timedim <- ncdim_def("time",tunits,as.double(t3)) # days since 1900

# define variables
fillvalue <- 1e32
dlname <- "2m air temperature"
tmp_def <- ncvar_def("tmp","deg_C",list(londim,latdim,timedim),fillvalue,dlname,prec="single")
dlname <- "mean_temperture_warmest_month"
mtwa_def <- ncvar_def("mtwa","deg_C",list(londim,latdim),fillvalue,dlname,prec="single")
dlname <- "mean_temperature_coldest_month"
mtco_def <- ncvar_def("mtco","deg_C",list(londim,latdim),fillvalue,dlname,prec="single")
dlname <- "mean_annual_temperature"
mat_def <- ncvar_def("mat","deg_C",list(londim,latdim),fillvalue,dlname,prec="single")

# create netCDF file and put arrays
ncfname <- "cru10min30_ncdf4.nc"
ncout <- nc_create(ncfname,list(tmp_def,mtco_def,mtwa_def,mat_def),force_v4=T)

# put variables
ncvar_put(ncout,tmp_def,tmp_array3)
ncvar_put(ncout,mtwa_def,mtwa_array3)
ncvar_put(ncout,mtco_def,mtco_array3)
ncvar_put(ncout,mat_def,mat_array3)

# put additional attributes into dimension and data variables
ncatt_put(ncout,"lon","axis","X") #,verbose=FALSE) #,definemode=FALSE)
ncatt_put(ncout,"lat","axis","Y")
ncatt_put(ncout,"time","axis","T")

# add global attributes
ncatt_put(ncout,0,"title",title$value)
ncatt_put(ncout,0,"institution",institution$value)
ncatt_put(ncout,0,"source",datasource$value)
ncatt_put(ncout,0,"references",references$value)
history <- paste("P.J. Bartlein", date(), sep=", ")
ncatt_put(ncout,0,"history",history)
ncatt_put(ncout,0,"Conventions",Conventions$value)

# close the file, writing data to disk
nc_close(ncout)

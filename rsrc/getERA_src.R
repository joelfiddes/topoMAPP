getERA<-function(dd, t, grd, stp, lt,typ,par,ar,tar,plev,workd){




#===============================================================================
# Define parameters
#===============================================================================
stream=	"'stream'    : 'oper'," # 
levtype=paste0("'levtype' : ","'",lt,"'",",") # sfc=surface or pl=pressure level
param=	paste0("'param'   : ","'",par,"'",",") # parameter code - check on ERA gui.
dataset=	"'dataset'    : 'interim'," # 
step=	paste("'step'    : ","'",stp,"'",",",sep='') #3/6/9/12 gives 3hr data for sfc ; 0 gives 6hr data for pl retrieval (3hr not possible)
grid=	paste("'grid'    : ","'",grd,"'",",",sep='') # resolution long/lat or grid single integer eg 80
time=	paste("'time'    : ","'",t,"'",",",sep='') #00/12 gives 3hr data for sfc retrieval ; 00/06/12/18 gives 6hr data for pl retrieval (3hr not possible) ; 00/12 for accumulated
date=	paste("'date'    : ","'",dd,"'",",",sep='') # date range yyyymmdd
class=	"'class'    : 'ei'," # 
format=	"'format'    : 'netcdf'," # 
target=	paste("'target'  : ","'",tar,"'",",",sep='') # target, only grib allowed
type=	paste("'type'    : ","'",typ,"'",",",sep='') #an=analysis or fc=forecast, depends on parameter - check on ERA gui.
area=	paste("'area'    : ","'",ar,"'",",",sep='') # region of interest N/W/S/E
#area=	"'area'    : '48.1/6/48 /6.1'," #TEST
plevel=	paste("'levelist': ","'",plev,"'",",",sep='')#pressure levels (mb)	
			#only written if levtype=pl
if(levtype=="'levtype' : 'pl'," ){plevel=plevel}else{plevel=NULL}
#write python script
filename = file(paste(workd, "/download_script.py", sep=""), open="wt")


#===============================================================================
# Write Python script
#===============================================================================
write("#!/usr/bin/python", filename)
write("from ecmwfapi import ECMWFDataServer", filename, append=TRUE)
write("server = ECMWFDataServer()", filename, append=TRUE)

write("server.retrieve({", filename, append=TRUE)

write("'dataset' : 'interim',", filename, append=TRUE)

write(stream, filename, append=TRUE)
write(levtype, filename, append=TRUE)
write(param, filename, append=TRUE)
write(dataset, filename, append=TRUE)
write(step, filename, append=TRUE)
write(grid, filename, append=TRUE)
write(time, filename, append=TRUE)
write(date, filename, append=TRUE)
write(class, filename, append=TRUE)
write(format, filename, append=TRUE)
write(target, filename, append=TRUE)
write(type, filename, append=TRUE)
write(area, filename, append=TRUE)
write(plevel, filename, append=TRUE)
write("    })", filename, append=TRUE)
close(filename)
setwd(workd)
system('chmod 777 download_script.py' )

#run script, download data
system('./download_script.py')

 }
#convert grib ->netcdf
# uses climate data operators (cdo) https://code.zmaw.de/projects/cdo

# folder=workd
# setwd(folder)
# files=list.files(folder, '.grb')
# name=unlist(strsplit(files, '.grb'))


# for (i in name){
# system(paste('cdo -f nc copy ', paste(i,'.grb',sep=''),' ', paste(i,'.nc', sep=''),sep=''))
# }



#vwind sfc fc 166.128
#uwind sfc fc 165.128
#2m dewpoint sfc fc 168.128
#2m air temp sfc fc 167.128
#ssrd sfc fc 169.128
#strd sfc fc 175.128
#totprecipi sfc fc 228.128
#convective precip sfc fc 143.128
#large scale precip sfc fc 142.128
#specific cloud liquid water 246.128
#TOA rad in 212.128
#surf pressure 134.128
#sealevel pressure 151.128
#vertical integral mass of atmosphere = 53.162
#total colum water fc 136.128
#total column ozone fc 206.128
#total column water vapour fc 137.128
#Surface net solar radiation, clear sky fc 210.128
#albedo an 174.128
#cloud press levels 248.128
#longwave surface net clear  211.128
#etc

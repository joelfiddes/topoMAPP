#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY
require(raster)

#SOURCE
source('tscale_src.R')
source('toposub_src.R')


#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1] #'/home/joel/sim/topomap_test/grid1' #
svfComp=args[2]

#====================================================================
# PARAMETERS FIXED
#====================================================================
#**********************  SCRIPT BEGIN *******************************
setwd(wd)

#===========================================================================
#				POINTS
#===========================================================================
mf=read.csv('listpoints.txt')
npoints=dim(mf)[1]


#========================================================================
#		READ INDIVIDUAL FIELD FILES
#========================================================================
tPoint=read.table('tPoint.txt' , header=T, sep=',')
rPoint=read.table('rPoint.txt', header=T, sep=',')
uPoint=read.table('uPoint.txt' , header=T, sep=',')
vPoint=read.table('vPoint.txt' , header=T, sep=',')
lwPoint=read.table('lwPoint.txt' , header=T, sep=',')
sol=read.table('sol.txt' , header=T, sep=',')
#solDir=read.table('solDir.txt' , header=T, sep=',')
#WsolDif=read.table('solDif.txt' , header=T, sep=',')
pSurf_lapse=read.table(  'pSurf_lapse.txt', header=T, sep=',')

#========================================================================
#		CALC WIND SPEED AND DIRECION FROM U/V
#========================================================================
u=uPoint
v=vPoint
wdPoint=windDir(u,v)
wsPoint=windSpd(u,v)


#========================================================================
#		MAKE MET FILES PER POINT
#========================================================================
load("../eraDat/all/datesSurf")
Date<-datesSurf_cut
Date<-format(as.POSIXct(Date), format="%d/%m/%Y %H:%M") #GEOtop format date

print("Generating the following meteo timeseries:")
print("*** HEAD ***")
head(Date)
print("*** TAIL ***")
tail(Date)

	for(i in 1:npoints)
	{
		#create directories for sims
		simindex=paste0('S',formatC(i, width=5,flag='0'))
		dir.create(simindex, recursive=TRUE)
		dir.create(paste0(simindex,'/out'), recursive=TRUE)
		dir.create(paste0(simindex,'/rec'), recursive=TRUE)

		Tair=round((tPoint[,i]-273.15),2) #K to deg
		RH=round(rPoint[,i],2)
		Wd=round(wdPoint[,i],2)
		Ws=round(wsPoint[,i],2)
		SW=round(sol[,i],2)
		#sdir=round(solDir[,i],2)
		#sdif=round(solDif[,i],2)
		LW=round(lwPoint[,i],2)
		Prec=round(pSurf_lapse[,i],5)
		meteo=cbind(Date,Tair,RH,Wd,Ws,SW,LW,Prec)
		#meteo=cbind(Date,Tair,RH,Wd,Ws,sdif,sdir,LW,Prec)
		
			if(length(which(is.na(meteo)==TRUE))>0)
			{
				print(paste0('WARNING:', length(which(is.na(meteo)==TRUE)), 'NANs found in meteofile: ',simindex))
			}

			if(length(which(is.na(meteo)==TRUE))==0)
			{
				print(paste0( length(which(is.na(meteo)==TRUE)), 'NANs found in meteofile: ',simindex))
			}

		write.table(meteo, paste(simindex,'/meteo0001.txt', sep=''), sep=',', row.names=F, quote=FALSE)




		#listp=data.frame(mf$id[i], mf$ele[i], mf$asp[i], mf$slp[i], mf$svf[i])
		listp=mf[1,]
		listp=round(listp,2)
		#names(listp)<-c('id', 'ele', 'asp', 'slp', 'svf')
		write.table(listp, paste0(simindex, '/listpoints.txt', sep=''), sep=',',row.names=F)



		#make horizon files MOVED TO SEPERATE SCRISPT

		if (svfComp == TRUE)
		{
			hor(listPath=simindex)
		}


	}

#====================================================================
# SETUP
#====================================================================
#INFO
# redo this as bash with sed

#DEPENDENCY
require(gdata)

#SOURCE
source('gt_control.R')
#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
geotopInputsPath=args[2] #'/home/joel/sim/topomap_test/grid1' #
startDate=args[3]
endDate=args[4]
#====================================================================
# PARAMETERS FIXED
#====================================================================
# 0. FIXED STUFF=soil_SANDYSILT (mean SILT + SAND) --> surface type vegetation
ThetaRes0=0.056
ThetaSat0=0.4305
AlphaVanGenuchten0=0.002
NVanGenuchten0=2.4
NormalHydrConductivity0=0.04375
LateralHydrConductivity0=0.04375

# 1. FIXED STUFF=soil_GRAVEL --> surfacetype debris
ThetaRes1=0.055
ThetaSat1=0.374
AlphaVanGenuchten1=0.1
NVanGenuchten1=2
NormalHydrConductivity1=1
LateralHydrConductivity1=1

# 2. FIXED STUFF=soil_ROCK --> surface type bedrock
ThetaRes2=0
ThetaSat2=0.05
AlphaVanGenuchten2=0.001
NVanGenuchten2=1.2
NormalHydrConductivity2=1e-06
LateralHydrConductivity2=1e-06



#========================================================================
#		MAKE GEOTOP INPTS FILE
#========================================================================
setwd(wd)

#========================================================================
#		FORMAT DATE
#========================================================================
d=strptime(startDate, format='%Y-%m-%d')
geotopStart=format(d, '%d/%m/%Y %H:%M')

d=strptime(endDate, format='%Y-%m-%d')
geotopEnd=format(d, '%d/%m/%Y %H:%M')
#========================================================================
#		Define land cover properties
#========================================================================

#numbers corrospond to ../landcoverZones.txt [lori numbers]
#vegetation [0]
#debris [1]
#bedrock [2]

surface=read.table('landcoverZones.txt',header=T, sep=',')
mf=read.csv('listpoints.txt')
npoints=dim(mf)[1]

# combine to dataframe
ThetaRes = c(ThetaRes1,ThetaRes2,ThetaRes0)
ThetaSat = c(ThetaSat1,ThetaSat2,ThetaSat0)
AlphaVanGenuchten             = c(AlphaVanGenuchten1,AlphaVanGenuchten2,AlphaVanGenuchten0)
NVanGenuchten                 = c(NVanGenuchten1,NVanGenuchten2,NVanGenuchten0)
NormalHydrConductivity        = c(NormalHydrConductivity1,NormalHydrConductivity2,NormalHydrConductivity0)
LateralHydrConductivity       = c(LateralHydrConductivity1,LateralHydrConductivity2,LateralHydrConductivity0)
surfacedf=data.frame(ThetaRes,ThetaSat,AlphaVanGenuchten,NVanGenuchten,NormalHydrConductivity,LateralHydrConductivity)


for(i in 1:npoints){
	simindex=paste0('S',formatC(i, width=5,flag='0'))
#expRoot= paste(spath, '/sim',i, sep='')
parfilename='geotop.inpts'
fs=readLines(geotopInputsPath) 


#datetime
start=gt.par.fline(fs=fs, keyword='InitDateDDMMYYYYhhmm') 
end=gt.par.fline(fs=fs, keyword='EndDateDDMMYYYYhhmm')

lnLat=gt.par.fline(fs=fs, keyword='Latitude') 
lnLong=gt.par.fline(fs=fs, keyword='Longitude') 
lnMetEle=gt.par.fline(fs=fs, keyword='MeteoStationElevation') 
lnPele=gt.par.fline(fs=fs, keyword='PointElevation') 
#soil
lntr=gt.par.fline(fs=fs, keyword='ThetaRes') 
lnts=gt.par.fline(fs=fs, keyword='ThetaSat') 
lnavg=gt.par.fline(fs=fs, keyword='AlphaVanGenuchten') 
lnnvg=gt.par.fline(fs=fs, keyword='NVanGenuchten')
lnnhc=gt.par.fline(fs=fs, keyword='NormalHydrConductivity')
lnlhc=gt.par.fline(fs=fs, keyword='LateralHydrConductivity')

#write datetime
fs=gt.par.wline(fs=fs,ln=start,vs=geotopStart)
fs=gt.par.wline(fs=fs,ln=end,vs=geotopEnd)

#getGridMeta feeds in here
fs=gt.par.wline(fs=fs,ln=lnLat,vs=mf$lat[i])
fs=gt.par.wline(fs=fs,ln=lnLong,vs=mf$lon[i])
fs=gt.par.wline(fs=fs,ln=lnMetEle,vs=mf$ele[i])
fs=gt.par.wline(fs=fs,ln=lnPele,vs=mf$ele[i])

#soil
lc=surface$value[i]+1 # add 1 to index 0->2 becomes 1->3
fs=gt.par.wline(fs=fs,ln=lntr,vs=surfacedf$ThetaRes[lc])
fs=gt.par.wline(fs=fs,ln=lnts,vs=surfacedf$ThetaSat[lc])
fs=gt.par.wline(fs=fs,ln=lnavg,vs=surfacedf$AlphaVanGenuchten[lc])
fs=gt.par.wline(fs=fs,ln=lnnvg,vs=surfacedf$NVanGenuchten[lc])
fs=gt.par.wline(fs=fs,ln=lnnhc,vs=surfacedf$NormalHydrConductivity[lc])
fs=gt.par.wline(fs=fs,ln=lnlhc,vs=surfacedf$LateralHydrConductivity[lc])

#snow - reduce on debris slopes
if(lc==3){
scf=gt.par.fline(fs=fs, keyword='SnowCorrFactor') 
fs=gt.par.wline(fs=fs,ln=scf,vs=0.4)
}
#gt.exp.write(eroot_loc=paste(simRoot, 'sim',i, sep=''),eroot_sim,enumber=1, fs=fs)
comchar<-"!" #character to indicate comments
con <- file(paste0(simindex,'/',parfilename), "w")  # open an output file connection
	cat(comchar,"SCRIPT-GENERATED EXPERIMENT FILE",'\n', file = con,sep="")
	cat(fs, file = con,sep='\n')
	close(con)

}


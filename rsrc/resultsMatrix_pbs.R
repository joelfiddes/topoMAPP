args = commandArgs(trailingOnly=TRUE)
wd = args[1]
grid = as.numeric(args[2])
nens = as.numeric(args[3])
Nclust = as.numeric(args[4])
sdThresh=as.numeric(args[5])
file=args[6]
param=args[7]

#===============================================================================
#			get results matrix
#===============================================================================
library(raster)

rstStack=stack()
for (i in 1: nens){ #python index

	resMat=c()
	for (j in 1: Nclust){ 
		simindex=paste0('S',formatC(j, width=5,flag='0'))
		dat = read.table(paste0(wd,"ensemble",i-1,"/grid",grid,"/", simindex,"/out/",file,".txt"), sep=',', header=T)
		tv <- dat[param]
		resMat = cbind(resMat,tv[,1]) # this index collapse 1 column dataframe to vector
		rst=raster(resMat)
	}
rstStack=stack(rstStack, rst)
ensembRes = as.array(rstStack)
}
save(ensembRes, file = paste0(wd, "/ensembRes.rd"))

#keep ensembRes swe
# ensembRes_swe <- ensembRes

# # compute sca results
# ensembRes[ensembRes<=sdThresh]<-0
# ensembRes[ensembRes>sdThresh]<-1
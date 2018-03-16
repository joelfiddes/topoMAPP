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
sink(paste0(wd, "/da_logfile"), append = TRUE)
rstStack=stack()
for (i in 1: nens){ #python index
print(paste0("processing ensemble ", i, " of ", nens ))
	resMat=c()
	simpaths =list.files(paste0(wd,"ensemble",i-1,"/grid",grid), pattern="S*")
	for (j in simpaths){ 
		#simindex=paste0('S',formatC(j, width=5,flag='0'))
		dat = read.table(paste0(wd,"ensemble",i-1,"/grid",grid,"/", j,"/out/",file,".txt"), sep=',', header=T)
		tv <- dat[param]
		resMat = cbind(resMat,tv[,1]) # this index collapse 1 column dataframe to vector
		rst=raster(resMat)
	}
rstStack=stack(rstStack, rst)
ensembResGST = as.array(rstStack)
}
save(ensembResGST, file = paste0(wd, "/ensembRes_",grid,"GST.rd"))
sink()
#keep ensembRes swe
# ensembRes_swe <- ensembRes

# # compute sca results
# ensembRes[ensembRes<=sdThresh]<-0
# ensembRes[ensembRes>sdThresh]<-1
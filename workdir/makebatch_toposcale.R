#====================================================================
# SETUP
#====================================================================
#INFO

#DEPENDENCY


#SOURCE

#====================================================================
# PARAMETERS/ARGS
#====================================================================
args = commandArgs(trailingOnly=TRUE)
wd=args[1]
#====================================================================
# PARAMETERS FIXED
#====================================================================

#**********************  SCRIPT BEGIN *******************************

batchfile=paste('batch_tscale.txt',sep='')
file.create(batchfile)

write('parallel   R CMD BATCH --no-save --no-restore ::: ./src/TopoAPP/tscale_SW.R ./src/TopoAPP/tscale_Rhum.R ./src/TopoAPP/tscale_windU.R ./src/TopoAPP/tscale_Tair.R ./src/TopoAPP/tscale_windV.R ./src/TopoAPP/tscale_P.R',file=batchfile,append=T)
#lwin is computed in toposcale_writeMet_parallel.r as dependent on T and R
system(paste('chmod 777 ','batch_tscale.txt',sep=''))


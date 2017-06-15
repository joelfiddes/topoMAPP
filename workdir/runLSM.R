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
lsmPath=args[2]



#========================================================================
#               make batch file
#========================================================================
setwd(wd)
batchfile='batch.txt'
file.create(batchfile)

sim_entries='result/S*'
write(paste('cd ',exePath,sep=''),file=batchfile,append=T)
write(paste('parallel', exe, ':::', sim_entries, sep=' '),file=batchfile,append=T)

system(paste('chmod 777 ',spath,'/batch.txt',sep=''))
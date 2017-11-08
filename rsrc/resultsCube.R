args = commandArgs(trailingOnly=TRUE)
gridpath=args[1] #'/home/joel/sim/topomap_test/grid1' #
#gridpath = "/home/joel/sim/da_test2/grid1/"

### Function to convert a list of dataframes to a 3D array
## All objects in the list will be dataframes with identical column headings.
list2ary = function(input.list){  #input a list of lists
  rows.cols <- dim(input.list[[1]])
  sheets <- length(input.list)
  output.ary <- array(unlist(input.list), dim = c(rows.cols, sheets))
  colnames(output.ary) <- colnames(input.list[[1]])
  row.names(output.ary) <- row.names(input.list[[1]])
  return(output.ary)    # output as a 3-D array
}

sRes.names = list.files(gridpath, pattern = "surface.txt", recursive=TRUE, full.name=TRUE)
sRes.list = lapply(sRes.names, FUN=read.csv,  sep=',', header=T)
sRes <- list2ary(sRes.list)  # convert to array
save(sRes,file = paste0(gridpath, "/surfaceResults"))

gRes.names= list.files(gridpath, pattern = "ground.txt", recursive=TRUE, full.name=TRUE)
gRes.list = lapply(gRes.names, FUN=read.csv,  sep=',', header=T)
gRes <- list2ary(gRes.list)  # convert to array
save(gRes, file = paste0(gridpath, "/groundResults"))

gRes.names= list.files(gridpath, pattern = "discharge.txt", recursive=TRUE, full.name=TRUE)
gRes.list = lapply(gRes.names, FUN=read.csv,  sep=',', header=T)
dRes <- list2ary(gRes.list)  # convert to array
save(dRes, file = paste0(gridpath, "/dischargeResults"))

# clean up system commands
#system(paste0("mkdir ", gridpath, "/archive"))
#system(paste0("mv ", gridpath,"/* " , gridpath, "/archive"))

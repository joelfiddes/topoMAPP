start = 1979
end = 2016
tv= "tair"
yearSeq = seq(1979,2016,1)
startSeq = paste0(yearSeq, "-01-01")
endSeq = paste0(yearSeq, "-12-31")


for (j in 1: length(yearSeq)){

starti = startSeq[j]
endi = endSeq[j]
call = paste("Rscript rsrc/transientMap.R /home/joel/sim/yala_interim_long/grid1/",tv,  starti, endi)
print(paste0("System call:", call ))
system(call)

}
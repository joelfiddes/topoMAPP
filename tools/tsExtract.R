fullpathsample  = "~/nas/sim/SIMS_JAN18/gcos_era5_sml_oldpars2/grid1/S00001" #args[1]
VAR = "gst" #args[2] # swe or hs or gst
STARTDAY ="01/09/2015" #args[2] # iso must match resol
ENDDAY = "01/09/2016" # =args[2] # iso
#resol = 1 # in h ONLY SUPPORT NATIVE OUTPUT IN DAYS 

# check that timedate and resol match

if(VAR == "gst") {datafile = "ground.txt"
	df = read.csv(paste0(fullpathsample, "/out/", datafile))
	dat = df$X100.000000

	ST = which (df$Date12.DDMMYYYYhhmm. == paste0(STARTDAY, " 00:00") )
	EN = which (df$Date12.DDMMYYYYhhmm. == paste0(ENDDAY, " 00:00"))
	dat.cut = dat[ST:EN]
}

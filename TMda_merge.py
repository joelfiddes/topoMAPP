#!/usr/bin/env python
# this _val version accepts vector of pixel numbers corresponding to val points then does computations only at these points to speed up analysis
# this has been superseded by dedicated scripts that do pointwise DA eg /home/joel/mnt/myserver/sim/wfj_compare/da_plot.sh
# Run as: joel@myserver:~/src/topoMAPP$ python TMda_merge.py ../../nas/sim/gcos_era5_big/gcos_era5_big.ini FALSE
# FALSE = only HX and WMAT are produced (normally what we want)
# TRUE = includes plot routines (original full pipline mode)


from configobj import ConfigObj
import logging
import subprocess
import os
from datetime import datetime, timedelta
from collections import OrderedDict
from dateutil.relativedelta import *

# assume start and end date are always 1 Sept (hydro years)
# cut multi year timeseries to single year blocks
# valShp only required if valMode = TRUE. This specifies set of MODIS pixels to run particle filter on (based on point locations), not whole domain 

def main(config, makePlots):
#def main(config, valShp = None, valMode = "FALSE"):
	config = ConfigObj(config)
	valShp =  config["ensemble"]["valShp"] #"/home/joel/nas/data/GCOS/metadata_easy.shp" # tske from config
	valMode= config["ensemble"]["valMode"] #"TRUE" # take from config

	# define variable
	wd = config["main"]["wd"]
	ensWd = wd.rstrip('//')+"_ensemble/"
	nens = config["ensemble"]["members"]
	Nclust=config["toposub"]["samples"]
	cores = config["geotop"]["num_cores"]
	valDat = config["main"]["datDir"] 
	
	# Fixed params - add to DA part of config
	sdThresh = str(13) # mm threshold of swe to sca conversion
	DSTART = str(270) # default start of melt in case algorithm fails
	DEND = str(330) # default end of melt in case algorithm fails
	R=str(0.016)
	file="surface" # separate key word [val? linked?]
	param = "snow_water_equivalent.mm." # separate key word [val? linked?]
	
	#	Logging
	logging.basicConfig(level=logging.DEBUG, filename=ensWd+"/da_logfile", filemode="a+",
                        format="%(asctime)-15s %(levelname)-8s %(message)s")
	logging.info("----- START data assimilation-----")
	logging.info("Make plots="+makePlots)


	# grids to loop over
	initgrids = config["main"]["initGrid"]
	
	# Identify hydro years (1 Sept -> 31 Aug)
	dates = [config["main"]["startDate"], config["main"]["endDate"]]
	start = datetime.strptime(dates[0], "%Y-%m-%d")
	end = datetime.strptime(dates[1], "%Y-%m-%d")
	dateList = OrderedDict(((start + timedelta(_)).strftime(r"%Y"), None) for _ in xrange((end - start).days)).keys()
	nHydroYrs = len(dateList) -1
	logging.info("----- Total simulation period = "+ str(dates) + " with " +str(nHydroYrs)+ " hydro years-----")


	for year in range(len(dateList)-1):

		start1 = start+relativedelta(years=+year) # 1 sept
		end1 = start+relativedelta(years=+(year+1)) # exactly 1 year later
		logging.info("----- Now calculating DA period = "+ str(start1)+" to " +str(end1) + "-----")

		for grid in initgrids:
			logging.info("-- DA run grid " +str(grid)+ "--")
			
			# Results matrix remains same in val mode
			# compute results matrix only once for entire timeseries - subsequent da years read in existing file
			fname = ensWd + "/ensembRes_"+grid+".rd"
			if os.path.isfile(fname) == False:
				# retrives swe results from all ensemble memebers and writes a 3d matrix (T,samples,ensembles)
				logging.info( "compute results matrix")
				cmd = ["Rscript",  "./rsrc/resultsMatrix_pbs.R" , ensWd , grid, nens , Nclust , sdThresh, file, param]
				subprocess.check_output(cmd)
			else:
				logging.info( fname+ " exists")

			# compute HX and weights for each da hydro year
			fname1 = ensWd + "/wmat_"+grid+str(year)+".rd"
			fname2 = ensWd + "/HX_"+grid+str(year)+".rd"
			if os.path.isfile(fname1) == False or os.path.isfile(fname2) == False:
				logging.info( "run PBS")
				cmd = ["Rscript",  "./rsrc/PBSpixel_merge.R" , ensWd , wd , grid , nens , Nclust , sdThresh , R , cores, DSTART , DEND, str(year), str(start1), str(end1), config["main"]["startDate"], config["main"]["endDate"], valShp, valMode]
				subprocess.check_output(cmd)
			else:
				logging.info( fname1+ "and" +fname2+ " exists")

			# compute sampleWeights
			# fname = ensWd + "/sampleWeights_"+grid+".rd"
			# if os.path.isfile(fname) == False:	
			# 	logging.info( "calc sample weights")
			# 	cmd = ["Rscript",  "./rsrc/PBSpix2samp_test.R", ensWd , wd , grid , nens , Nclust , sdThresh , R , cores, str(year)] 
			# 	subprocess.check_output(cmd)	
			# else:
			# 	logging.info( fname+ " exists")
			if makePlots=="TRUE":
				# make plot dir
				mydir = ensWd+"/plots"
				if not os.path.exists(mydir):
						os.makedirs(mydir)

				# SCA plots	
				fname = ensWd+"/plots/fSCA_plot"+grid+str(year)+".pdf"
				if os.path.isfile(fname) == False:
					logging.info( "plot SCA")
					cmd = ["Rscript",  "./rsrc/daSCAplot_merge.R", ensWd ,wd,grid ,nens ,valShp, DSTART, DEND, str(year), valMode ] 
					subprocess.check_output(cmd)
				else:
					logging.info( "skip sca plot routine")

				# SWE plot
				fname = ensWd+"/plots/swe_pix"+grid+str(year)+".pdf"
				if os.path.isfile(fname) == False:
					logging.info( "plot swe")
					cmd = ["Rscript",  "./rsrc/daSWEplot_pixPost_merge.R", ensWd,wd ,grid ,nens, valShp, str(year), str(start1), str(end1), config["main"]["startDate"], config["main"]["endDate"], valDat, valMode ]
					subprocess.check_output(cmd)
				else:
					logging.info("skip swe plot")

			# SCA grid plot
				logging.info( "calc SCA grid= OFF")
			#cmd = ["Rscript",  "./rsrc/PBSgrid2.R" ,  ensWd , wd , grid , nens , Nclust , sdThresh , R , DSTART , DEND] 
			#subprocess.check_output(cmd)

			# fname = ensWd+"/plots/da_plots"+grid+str(year)+".pdf"
			# if os.path.isfile(fname) == False:
			# 	cmd = ["convert" , ensWd+"*.pdf" ,  ensWd+"da_plots"+grid+str(year)+".pdf"]
			# 	subprocess.check_output(cmd)



			# 	os.rename(ensWd+"da_plots"+grid+str(year)+".pdf" , ensWd+"/plots/da_plots"+grid+str(year)+".pdf")	
			# else:
			# 	logging.info("skip pdf merge")
			
			logging.info( "DA run complete!")
#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys

	config      = sys.argv[1]
	makePlots      = sys.argv[2]
	main(config,makePlots)

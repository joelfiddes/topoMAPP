#!/usr/bin/env python
from configobj import ConfigObj
import logging
import subprocess
import os
from datetime import datetime, timedelta
from collections import OrderedDict
from dateutil.relativedelta import *

# assume start and end date are always 1 Sept (hydro years)
# cut multi year timeseries to single year blocks
def main(config):

	config = ConfigObj(config)
	# define variable
	sca_wd = "/home/joel/sim/MODIS_ALPS_DA"# full path to contains all the modis data # ~/nas/sim/snow/sca_poly/Snow_Cov_Daily_500m_v5
	wd = "/home/joel/sim/wfj_interim2_ensemble_v1/"
	priorwd = "/home/joel/sim/wfj_interim2/"
	initgrids = str(1)
	nens = str(50)
	Nclust=str(150)


	cores = str(4)
	sdThresh = str(13) # mm threshold of swe to sca conversion
	DSTART = str(210) # default start of melt in case algorithm fails
	DEND = str(350) # default end of melt in case algorithm fails
	valshp = "/home/joel/mnt/nas/data/GCOS/metadata_easy.shp"
	R=str(0.016)
	file="surface" # separate key word [val? linked?]
	param = "snow_water_equivalent.mm." # separate key word [val? linked?]
	valDat = "/home/joel/mnt/nas/data/GCOS/"
	#	Logging
	logging.basicConfig(level=logging.DEBUG, filename=wd+"/da_logfile", filemode="a+",
                        format="%(asctime)-15s %(levelname)-8s %(message)s")
	logging.info("----- START data assimilation-----")

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
			
			# compute results matrix only once for entire timeseries - subsequent da years read in existing file
			fname = wd + "/ensembRes_"+grid+".rd"
			if os.path.isfile(fname) == False:
				# retrives swe results from all ensemble memebers and writes a 3d matrix (T,samples,ensembles)
				logging.info( "compute results matrix")
				cmd = ["Rscript",  "./rsrc/resultsMatrix_pbs.R" , wd , grid, nens , Nclust , sdThresh, file, param]
				subprocess.check_output(cmd)
			else:
				logging.info( fname+ " exists")

			# compute HX and weights for each da hydro year
			fname1 = wd + "/wmat_"+grid+str(year)+".rd"
			fname2 = wd + "/HX_"+grid+str(year)+".rd"
			if os.path.isfile(fname1) == False or os.path.isfile(fname2) == False:
				logging.info( "run PBS")
				cmd = ["Rscript",  "./rsrc/PBSpixel.R" , wd , priorwd , sca_wd , grid , nens , Nclust , sdThresh , R , cores, DSTART , DEND, str(year), str(start1), str(end1), config["main"]["startDate"], config["main"]["endDate"]]
				subprocess.check_output(cmd)
			else:
				logging.info( fname1+ "and" +fname2+ " exists")

			# compute sampleWeights
			fname = wd + "/sampleWeights_"+grid+".rd"
			if os.path.isfile(fname) == False:	
				logging.info( "calc sample weights")
				cmd = ["Rscript",  "./rsrc/PBSpix2samp_test.R", wd , priorwd , grid , nens , Nclust , sdThresh , R , cores, str(year) ] 
				subprocess.check_output(cmd)	
			else:
				logging.info( fname+ " exists")

			# SCA plots	
			logging.info( "plot SCA")
			cmd = ["Rscript",  "./rsrc/daSCAplot.R", wd ,priorwd,grid ,nens ,valshp, DSTART, DEND, str(year) ] 
			subprocess.check_output(cmd)

			# SWE plot
			logging.info( "plot swe")
			cmd = ["Rscript",  "./rsrc/daSWEplot_pixPost.R", wd,priorwd ,grid ,nens, valshp, str(year), str(start1), str(end1), config["main"]["startDate"], config["main"]["endDate"], valDat]
			subprocess.check_output(cmd)

			# SCA grid plot
			logging.info( "calc SCA grid= OFF")
			#cmd = ["Rscript",  "./rsrc/PBSgrid2.R" ,  wd , priorwd , grid , nens , Nclust , sdThresh , R , DSTART , DEND] 
			#subprocess.check_output(cmd)


			cmd = ["convert" , wd+"*.pdf" ,  wd+"da_plots.pdf"]
			subprocess.check_output(cmd)
			logging.info( "DA run complete!")
#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys

	config      = sys.argv[1]
	main(config)

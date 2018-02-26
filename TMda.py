#!/usr/bin/env python
from configobj import ConfigObj
import logging
import subprocess
import os

def main(config):

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
	valshp = "/home/joel/data/GCOS/metadata_easy.shp"
	R=str(0.016)
	file="surface" # separate key word [val? linked?]
	param = "snow_water_equivalent.mm." # separate key word [val? linked?]

	#	Logging
	logging.basicConfig(level=logging.DEBUG, filename=wd+"/da_logfile", filemode="a+",
                        format="%(asctime)-15s %(levelname)-8s %(message)s")
	logging.info("----- START data assimilation-----")

	for grid in initgrids:
		logging.info("----- DA run grid " +str(grid)+ "-----")
		
		# compute results matrix
		fname = wd + "/ensembRes_"+grid+".rd"
		if os.path.isfile(fname) == False:
			# retrives swe results from all ensemble memebers and writes a 3d matrix (T,samples,ensembles)
			logging.info( "compute results matrix")
			cmd = ["Rscript",  "./rsrc/resultsMatrix_pbs.R" , wd , grid, nens , Nclust , sdThresh, file, param]
			subprocess.check_output(cmd)
		else:
			logging.info( fname+ " exists")

		# compute HX and weights
		fname1 = wd + "/wmat_"+grid+".rd"
		fname2 = wd + "/HX_"+grid+".rd"
		if os.path.isfile(fname1) == False | os.path.isfile(fname2) == False:
			logging.info( "run PBS")
			cmd = ["Rscript",  "./rsrc/PBSpixel.R" , wd , priorwd , sca_wd , grid , nens , Nclust , sdThresh , R , cores, DSTART , DEND]
			subprocess.check_output(cmd)
		else:
			logging.info( fname1+ "and" +fname2+ " exists")

		# compute sampleWeights
		fname = wd + "/sampleWeights_"+grid+".rd"
		if os.path.isfile(fname) == False:	
			logging.info( "calc sample weights")
			cmd = ["Rscript",  "./rsrc/PBSpix2samp_test.R", wd , priorwd , grid , nens , Nclust , sdThresh , R , cores ] 
			subprocess.check_output(cmd)	
		else:
			logging.info( fname+ " exists")

		# SCA plots	
		logging.info( "plot SCA")
		cmd = ["Rscript",  "./rsrc/daSCAplot.R", wd ,priorwd,grid ,nens ,valshp, DSTART, DEND ] 
		subprocess.check_output(cmd)

		# SWE plot
		logging.info( "plot swe")
		cmd = ["Rscript",  "./rsrc/daSWEplot_pixPost.R", wd,priorwd ,grid ,nens, valshp]
		subprocess.check_output(cmd)

		# SCA grid plot
		logging.info( "calc SCA grid")
		cmd = ["Rscript",  "./rsrc/PBSgrid2.R" ,  wd , priorwd , grid , nens , Nclust , sdThresh , R , DSTART , DEND] 
		subprocess.check_output(cmd)


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

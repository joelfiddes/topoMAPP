#!/usr/bin/env python
import os
import pandas as pd
import time
import sys
from configobj import ConfigObj
import logging

#===============================================================================================
# PARAMETERS TO SET

#root = "/home/joel/sim/ensembler_test/"
#inifile="test.ini"
#initdir='/home/joel/sim/test_radflux'
#initgrid = "2" # must be a single grid for ensdemble runs - do not support "*" all grids yet
#N = 100# number of ensemble memebers

def main(config):

	initgrid = config['main']['initGrid']
	root = config['main']['wd'].rstrip("/") + "_ensemble"
	N = config['ensemble']['members']
	#initdir = config['main']['initDir']
	master = config['main']['wd'] # get initDir from master wd


	#===============================================================================================

	# Timer
	start_time = time.time()

	# Creat wd dir if doesnt exist
	if not os.path.exists(root):
		os.makedirs(root)

	#	Logging
	logging.basicConfig(level=logging.DEBUG, filename=root+"/logfile", filemode="a+",
                        format="%(asctime)-15s %(levelname)-8s %(message)s")

	# write copy of config for ensemble editing
	config.filename = root +"/ensemble_config.ini"
	config.write()
	config = ConfigObj(config.filename)
	

	# start ensemble runs
	logging.info("Running ensemble members: " + str(N))

	#generate ensemble
	os.system("Rscript rsrc/ensemGen.R " + str(N))

	# read in csv as pd data
	df = pd.read_csv("ensemble.csv")

	# Assimilation cycle loop start here

	#loop over ensemble members
	for i in range(0,int(N)):
		logging.info("Running ensemble member:" + str(i))
		pbias = df['pbias'][i]
		tbias = df['tbias'][i]
		lwbias = df['lwbias'][i]
		swbias = df['swbias'][i]

		logging.info("[INFO]: Config ensemble members")
		#config = ConfigObj(inifile)
		#config.filename = inifile
		config["main"]["wd"]  = root + "/ensemble" + str(i) + "/"
		config["da"]["pscale"] = pbias #factor to multiply precip by
		config["da"]["tscale"] = tbias #factor to add to temp
		config["da"]["swscale"] = swbias
		config["da"]["lwscale"] = lwbias
		config['modis']['getMODISSCA'] = "FALSE"
		config["main"]["initSim"]  = 'TRUE'
		config['main']['initDir'] = master
		config['toposub']['inform'] = 'FALSE'
		config['main']['initGrid'] = initgrid
		config.write()

		logging.info("Config settings used")
		logging.info(config)

		#print "[INFO]: Running topomapp_main.py"
		#os.system("python topomapp_main.py " + inifile)

		# init a new instance from 	initdir and initgrid
		import TMinit
		TMinit.main(config, ensembRun=True)

		# define Ngrid in ensemble directory
		Ngrid = config["main"]["wd"] +"grid"+ initgrid
		logging.info("Ngrid= " + Ngrid)

		# run setup scaling of meteo and LSM - would be quicker to read meteo sclae and then write back
		import TMensembSim
		TMensembSim.main(Ngrid, config)

		# report time of run
		logging.info("%f minutes for run of ensemble members" % round((time.time()/60 - start_time/60),2))



#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys

	config      = sys.argv[1]
	main(config)


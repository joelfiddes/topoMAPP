#!/usr/bin/env python
import os
import subprocess
import pandas as pd
import time
import sys
from configobj import ConfigObj
import logging

# need to reverse these loops; INITGRID FIRST then ensemble loop. That way garantee at least some complete ensembles, otherwise need wait till all ensemble memebers are done to get any results at all - sensitive to failure. 

def main(config):


	initgrids = config['main']['initGrid']
	root = config['main']['wd'].rstrip("/") + "_ensemble"
	N = config['ensemble']['members']
	#initdir = config['main']['initDir']
	master = config['main']['wd'] # get initDir from master wd


	# Creat wd dir if doesnt exist
	if not os.path.exists(root):
		os.makedirs(root)

	#	Logging
	logging.basicConfig(level=logging.DEBUG, filename=root+"/logfile", filemode="a+",
                        format="%(asctime)-15s %(levelname)-8s %(message)s")
	logging.info("----- START ENSEMBLE RUNS-----")

	# write copy of config for ensemble editing
	config.filename = root +"/ensemble_config.ini"
	config.write()
	config = ConfigObj(config.filename)
	

	# start ensemble runs
	logging.info("Running " + str(N) + " ensemble members." )

	#generate ensemble
	subprocess.call(["Rscript", "rsrc/ensemGen.R" , str(N) , root])

	# read in csv as pd data
	df = pd.read_csv(root+"/ensemble.csv")

	# Assimilation cycle loop start here

	#loop over ensemble members
	for i in range(0,int(N)):

		# Loop Timer
		start_time = time.time()

		logging.info("----- Start ensemble member: " + str(i) + "-----")
		pbias = df['pbias'][i]
		tbias = df['tbias'][i]
		lwbias = df['lwbias'][i]
		swbias = df['swbias'][i]

		
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
		#config['main']['initGrid'] = initgrid
		config.write()

		logging.info("Config settings used")
		logging.info(config)

		# check if runSucess exists and skip if true
		fname1 = config['main']['wd'] + "/.runSuccess"
		if os.path.isfile(fname1) == False: 

		

			#print "[INFO]: Running topomapp_main.py"
			#os.system("python topomapp_main.py " + inifile)

			for initgrid in initgrids:
				print initgrid
				config['main']['initGrid'] = initgrid
				config.write()
				# init a new instance from 	initdir and initgrid
				import TMinit
				TMinit.main(config, ensembRun=True)

				# define Ngrid in ensemble directory
				Ngrid = config["main"]["wd"] +"grid"+ initgrid
				logging.info("Ngrid= " + Ngrid)

				# run setup scaling of meteo and LSM - would be quicker to read meteo sclae and then write back
				import TMensembSim
				TMensembSim.main(Ngrid, config)

			f= open(config['main']['wd'] + "/.runSuccess","w+")
			f.close() 
			logging.info("%f minutes for run of ensemble member" % round((time.time()/60 - start_time/60),2))

		else:
			logging.info(config['main']['wd'] + " already exists")	
		# report time of run
		


#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys

	config      = sys.argv[1]
	main(config)


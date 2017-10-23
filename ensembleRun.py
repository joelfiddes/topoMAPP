#!/usr/bin/env python
import os
import pandas as pd
import time
import sys
from configobj import ConfigObj
args = config
#===============================================================================================
# PARAMETERS TO SET

#root = "/home/joel/sim/ensembler_test/"
#inifile="test.ini"
#initdir='/home/joel/sim/test_radflux'
#initgrid = "2" # must be a single grid for ensdemble runs - do not support "*" all grids yet
#N = 100# number of ensemble memebers

def main(config):
	initgrid = config['main']['initGrid']
	root = config['main']['wd'] + "_ensemble"
	N = config['ensemble']['members']
	#initdir = config['main']['initDir']
	master = config['main']['wd'] # get initDir from master wd
	#===============================================================================================

	# Timer
	start_time = time.time()

	# Creat wd dir if doesnt exist
	if not os.path.exists(root):
		os.makedirs(root)

	# start ensemble runs
	print "Running ensemble members: " + str(N)

	#generate ensemble
	os.system("Rscript rsrc/ensemGen.R " + str(N))

	# read in csv as pd data
	df = pd.read_csv("ensemble.csv")

	# Assimilation cycle loop start here

	#loop over ensemble members
	for i in range(0,N):
		print "Running ensemble member:" + str(i)
		pbias = df['pbias'][i]
		tbias = df['tbias'][i]
		lwbias = df['lwbias'][i]
		swbias = df['swbias'][i]

		print "[INFO]: Config ensemble members"
		#config = ConfigObj(inifile)
		#config.filename = inifile
		config["main"]["wd"]  = root + "ensemble" + str(i) + "/"
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

		print "[INFO]: Config settings used"
		print(config)

		#print "[INFO]: Running topomapp_main.py"
		#os.system("python topomapp_main.py " + inifile)

		# init a new instance from 	initdir and initgrid
		import TMinit
		TMinit.main(config, ensembRun=True)

		# define Ngrid
		Ngrid = config["main"]["initDir"] + "/grid" + config["main"]["initGrid"]
		print "[INFO]: INIT grid = " + Ngrid

		# run setup scaling of meteo and LSM - would be quicker to read meteo sclae and then write back
		import TMsim
		TMsim.main(Ngrid, config)



#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys
	config      = sys.argv[1]
	main(config)

print("[INFO]: %f minutes for run of ensemble members" % round((time.time()/60 - start_time/60),2))
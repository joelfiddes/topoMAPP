#!/usr/bin/env python
import subprocess
import glob
import logging
import os

def main(Ngrid, config):
#====================================================================
#	Setup Geotop simulations
#====================================================================
	#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
	print "[INFO]: Setup Geotop simulations" 

	# set up sim directoroes #and write metfiles
	#for Ngrid in range(1,int(ncells)+1):
		#gridpath = wd +"/grid"+ Ngrid

	#for Ngrid in grid_dirs:	
	gridpath = str(Ngrid)

	import os
	if os.path.exists(gridpath):
		print "[INFO]: Setting up geotop inputs " + str(Ngrid)

	 	print "[INFO]: Creating met files...."
	 	from gtop_setup import prepMet as met
		met.main(gridpath, config["toposcale"]["svfCompute"],str(config["da"]["tscale"]),str(config["da"]["pscale"]),str(config["da"]["swscale"]),str(config["da"]["lwscale"]))

		print "[INFO]: extract surface properties"
		from gtop_setup import pointsSurface as psurf
		psurf.main(gridpath)

		print "[INFO]: making inputs file"
		from gtop_setup import makeGeotopInputs as gInput
		gInput.main(gridpath, config["geotop"]["geotopInputsPath"], config["main"]["startDate"], config["main"]["endDate"])

	else:
		print "[INFO]: " + str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid) + "+1"


#====================================================================
#	Run LSM
#====================================================================
	print "[INFO]: Running LSM" 

	# set up sim directoroes #and write metfiles

	gridpath = Ngrid

	if os.path.exists(gridpath):

	 	print "[INFO]: Simulations grid " + str(Ngrid) + " running (parallel model runs)"
		
		# batchfile="batch.sh"
		# sim_entries=gridpath +"/S*"
		# f = open(batchfile, "w+")
		# f.write("#!/bin/bash"+ "\n")
		# f.write("cd " + config["geotop"]["lsmPath"] + "\n")
		# # max 8 jobs set here
		# f.write("parallel -j 8 " + "./" + config["geotop"]["lsmExe"] + " ::: " + sim_entries + "\n")
		# f.close()
		# import os, sys, stat
		# os.chmod(batchfile, stat.S_IRWXU)
		# cmd     = ["./" + batchfile]
		# subprocess.check_output( "./" + batchfile )

		# ====== joblib spawning too many processes =====
		import subprocess
		from joblib import Parallel, delayed 
		import multiprocessing 
		jobs = glob.glob(gridpath +"/S*")
		logging.info( "Running "+str(len(jobs))+ " multiprocessing jobs " )
		num_cores= config['geotop']['num_cores'] #multiprocessing.cpu_count()
		Parallel(n_jobs=int(num_cores))(delayed(subprocess.call)([config['geotop']['lsmPath'] + '/' + config['geotop']['lsmExe'], i ]) for i in jobs)
		# ===============================================

	else:
		print "[INFO]: " + str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid) + "+1"

	# count sim dirs produce SUCCES file if complete
	sim_dirs = glob.glob(gridpath +"/S*")
	nsims = len(sim_dirs)
	if nsims == config["toposub"]["samples"]:
		file = open(gridpath + “/RUNSUCCESS”,”w”) 
		file.close() 

#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys
	Ngrid      = sys.argv[1]
	config      = sys.argv[2]
	main(Ngrid, config)
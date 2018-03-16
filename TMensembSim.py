#!/usr/bin/env python
""" 
This module scale meteo0001.txt files directly with ensemble perturbations. And then runs LSM
 

"""
import subprocess
import glob
import logging
import os
import pandas as pd

def main(Ngrid, config):

	#list sim dirs
	sim_dirs = glob.glob(Ngrid +"/S*")

	logging.info("Perturburbing simulation meteo files")
	# logging.info(sim_dirs)

	# loop through sim dirs
	for s in sim_dirs:

	# read meteo0001
		df = pd.read_csv( s +"/meteo0001.txt")

	# scale meteo
	#https://www.the-cryosphere.net/10/103/2016/tc-10-103-2016.pdf
	
		df['Prec'] = df['Prec'] * config['da']['pscale'] #multiplicative
		df['LW'] = df['LW'] * config['da']['lwscale']##multiplicative
		df['SW'] = df['SW'] * config['da']['swscale']##multiplicative
		
		# convert to K
		taK = df['Tair'] + 273.15
		# peturb and back to celcius
		df['Tair'] = (taK*config['da']['tscale']) - 273.15

		#write meteo
		df.to_csv( s +"/meteo0001.txt", index = False)




#====================================================================
#	Run LSM
#====================================================================
	logging.info("Running LSM")

	# set up sim directoroes #and write metfiles

	gridpath = Ngrid

	if os.path.exists(gridpath):

	 	logging.info("Simulations grid " + str(Ngrid) + " running (parallel model runs)")
		
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
		logging.info("[INFO]: " + str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid) + "+1")

#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys
	Ngrid      = sys.argv[1]
	config      = sys.argv[2]
	main(Ngrid, config)



	#config['geotop']['lsmPath']+'/'+config['geotop']['lsmExe']
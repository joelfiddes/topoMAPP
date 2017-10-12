#!/usr/bin/env python
# import ipdb
# ipdb.set_trace

"""
INI file should be configured named and supplied as argument of fullpathtofile or just filename if in curent wd eg 

run python code_da.py yala.ini"""


""" This is a port of run_points.sh"""
import sys
import os
import subprocess
import logging
import os.path
from listpoints_make import getRasterDims as dims
import glob
#============= LOGGING =========================================

#logging.basicConfig(level=logging.INFO)
#logger = logging.getLogger(__name__)

# logger.info("Start reading database")
# # read database here
# records = {"john": 55, "tom": 66}
# logger.debug("Records: %s", records)
# logger.info("Updating records ...")
# # update records here
# logger.info("Finish updating records")

# v2 
#import logging
# import logging.handlers
# log = logging.getLogger(__name__)
# log.addHandler(logging.StreamHandler())  # Prints to console.
# log.addHandler(logging.handlers.RotatingFileHandler("logfile.log"))
# log.setLevel(logging.INFO)  # Set logging level here.
#================================================================


sys.path.append("/home/joel/src/topoMAPP/")
print sys.path
print sys.argv[0]
# print "sys.argv", sys.argv
# print "sys.path", sys.path
# print os.path.split(sys.argv[0])[0]
# sys.path.append(os.path.split(sys.argv[0])[0])

# TODO:
# read config - this gives srcdir and wd + other params
# declare wd once here
# syspath append get relative path


#====================================================================
#	Timer
#====================================================================
import time
start_time = time.time()

#====================================================================
#	Config setup
#====================================================================
#os.system("python writeConfig.py") # update config DONE IN run.sh file

from configobj import ConfigObj
config = ConfigObj(sys.argv[1])

wd = config["main"]["wd"] # set commonly used configs

#====================================================================
#	Creat sim dir if doesnt exist
#====================================================================
directory = os.path.dirname(wd)
if not os.path.exists(directory):
	os.makedirs(directory)

print "[INFO]: Simulation directory:" + wd  

#====================================================================
#	Initialise run: this can be used to copy meteo and surfaces to a new sim directory. 
# 	Main application is in ensemble runs
#====================================================================
if config["main"]["initSim"] == "TRUE":
	print "[INFO]: initialising " + wd + " from " + config["main"]["initDir"]
	print "[INFO]: copying only Grid" + config["main"]["initGrid"]

	src = config["main"]["initDir"] + "/eraDat"
	dst = wd
	cmd = "cp -r %s %s"%(src,dst)
	os.system(cmd)

	src = config["main"]["initDir"] + "/predictors"
	cmd = "cp -r %s %s"%(src,dst)
	os.system(cmd)

	src = config["main"]["initDir"] + "/spatial"
	cmd = "cp -r %s %s"%(src,dst)
	os.system(cmd)

	src = config["main"]["initDir"] + "/grid" + config["main"]["initGrid"]
	cmd = "cp -r  %s %s"%(src,dst)
	os.system(cmd)
  
#====================================================================
# Copy config to simulation directory
#==================================================================== 
configfilename = os.path.basename(sys.argv[1])

config.filename = wd + configfilename
config.write()

#====================================================================
#	Setup domain
#====================================================================

# control statement to skip if "asp.tif" exist - indicator fileNOT ROBUST
fname = wd + "predictors/asp.tif"
if os.path.isfile(fname) == False:		

	# Dop this only for bbox runs
	if config["main"]["runtype"] == "bbox":

		# copy preexisting dem
		if config["main"]["demexists"] == "TRUE":

			cmd = "mkdir " + wd + "/predictors/"
			os.system(cmd)
			src = config["main"]["dempath"]
			dst = wd +"/predictors/dem.tif"
			cmd = "cp -r %s %s"%(src,dst)
			os.system(cmd) 

		# fetch new srtm dem from nasa
		elif config["main"]["demexists"] == "FALSE":

			from domain_setup import getDEM as gdem
			gdem.main(wd ,config["main"]["demDir"] ,config["main"]["lonw"],config["main"]["lats"],config["main"]["lone"],config["main"]["latn"])

	# do this only for point runs		
	if config["main"]["runtype"] == "points":

		from domain_setup import getDEM_points as gdem
		gdem.main(wd ,config["main"]["demDir"] ,config["era-interim"]["grid"], config["main"]["pointsFile"], config["main"]["lonCol"], config["main"]["latCol"])

		from domain_setup import makeShape as shp
		shp.main(wd , config["main"]["pointsFile"], config["main"]["lonCol"], config["main"]["latCol"])

	from domain_setup import clipToEra as era
	era.main(wd ,config["era-interim"]["grid"])

	if config["main"]["runtype"] == "bbox":
		from domain_setup import domainPlot as dplot
		dplot.main(wd , "FALSE") # shp = TRUE for points  run

		cmd = "Rscript ./rsrc/makePoly.R " +config['main']['latn']+" "+config['main']['lats']+" " +config['main']['lone']+" "+config['main']['lonw']+" "+wd+"/spatial/extentRequest.shp"
		os.system(cmd)

	if config["main"]["runtype"] == "points":
		from domain_setup import domainPlot as dplot
		dplot.main(wd , "TRUE") # shp = TRUE for points  run

	from domain_setup import makeKML as kml
	kml.main(wd, wd + "/predictors/ele.tif", "shape", wd + "/spatial/extent")
	        
	kml.main(wd, wd + "/spatial/eraExtent.tif", "raster", wd + "/spatial/eraExtent")

	#kml.main(wd, wd + "/spatial/extentRequest.shp", "raster", wd + "/spatial/extentRequest")

	from domain_setup import computeTopo as topo
	topo.main(wd, config["toposcale"]["svfCompute"])

	#from domain_setup import makeSurface as surf # WARNING huge memory use (10GB)
	#surf.main(wd, config["modis"]["MODISdir"] )
	#MOVED: to toposub or listpoints to ensiure is run on only one grid at a time, reduce memory load.

else:
	print "[INFO]: topo predictors precomputed"

#====================================================================
#	GET ERA
#====================================================================


fname1 = wd + "eraDat/SURF.nc"
fname2 = wd + "eraDat/PLEVEL.nc"
if os.path.isfile(fname2) == False and os.path.isfile(fname2) == False: #NOT ROBUST

	# from getERA import getExtent as ext
	# latN = ext.main(wd + "/predictors/ele.tif" , "latN")
	# latS = ext.main(wd + "/predictors/ele.tif" , "latS")
	# lonW = ext.main(wd + "/predictors/ele.tif" , "lonW")
	# lonE = ext.main(wd + "/predictors/ele.tif" , "lonE")

	from getERA import extractEraBbox as ext
	latN = ext.main(config['main']['srcdir']+"/dat/eraigrid75.tif" , "latN",config["main"]["lonw"],config["main"]["lone"],config["main"]["lats"],  config["main"]["latn"])

	latS = ext.main(config['main']['srcdir']+"/dat/eraigrid75.tif", "latS", config["main"]["lonw"] ,config["main"]["lone"],config["main"]["lats"],  config["main"]["latn"])

	lonW = ext.main(config['main']['srcdir']+"/dat/eraigrid75.tif", "lonW", config["main"]["lonw"] ,config["main"]["lone"],config["main"]["lats"],  config["main"]["latn"])

	lonE = ext.main(config['main']['srcdir']+"/dat/eraigrid75.tif" ,"lonE",	config["main"]["lonw"],	config["main"]["lone"],	config["main"]["lats"],  config["main"]["latn"] )



	eraDir = wd + "/eraDat"
	if not os.path.exists(eraDir):
		os.mkdir(eraDir)


	from getERA import eraRetrievePLEVEL as plevel
	print "Retrieving ECWMF pressure-level data"
	plevel.retrieve_interim( config["main"]["startDate"], config["main"]["endDate"], latN, latS, lonE, lonW, config["era-interim"]["grid"],eraDir)

	from getERA import eraRetrieveSURFACE as surf
	print "Retrieving ECWMF surface data"
	surf.retrieve_interim(config["main"]["startDate"], config["main"]["endDate"], latN, latS, lonE, lonW, config["era-interim"]["grid"],eraDir)

	# Merge NC timeseries (requires linux package cdo)
	import subprocess
	#os.chdir(eraDir)
	cmd     = "cdo -b F64 -f nc2 mergetime " + wd + "/eraDat/interim_daily_PLEVEL* " +  wd + "/eraDat/PLEVEL.nc"

	if os.path.exists(wd + "eraDat/PLEVEL.nc"):
	    os.remove(wd + "eraDat/PLEVEL.nc")
	    print "removed original PLEVEL.nc"

	print("Running:" + str(cmd))
	subprocess.check_output(cmd, shell = "TRUE")

	cmd     = "cdo -b F64 -f nc2 mergetime " + wd +  "/eraDat/interim_daily_SURF* " + wd +"/eraDat/SURF.nc"

	if os.path.exists(wd + "eraDat/SURF.nc"):
	    os.remove(wd + "eraDat/SURF.nc")
	    print "removed original SURF.nc"

	print("[INFO]: Running:" + str(cmd))
	subprocess.check_output(cmd, shell = "TRUE")


else:
	print "[INFO]: SURF.nc and PLEVEL.nc precomputed"

	#os.chdir(config["main"]["srcdir"])
from getERA import era_prep as prep
prep.main(wd, config["main"]["startDate"], config["main"]["endDate"])

if config["main"]["initSim"] != "TRUE":
	from getERA import prepSims as sim
	sim.main(wd)

# define ncells here based on occurances of grid* directoriers created by prepSims or copied if initSim == True
grid_dirs = glob.glob(wd +"/grid*")
ncells = len(grid_dirs)
print "[INFO]: This simulation contains ", ncells, " grids"
print "[INFO]: grids to be computed " + str(grid_dirs)

#====================================================================
#	TOPOSUB: Toposub.R contains hardcoded "normal" parameters 
#====================================================================
from utils import fileSearch
path=wd
file="landform.tif"
x=fileSearch.search(path, file)
if x != 1: #NOT ROBUST

	if config["main"]["runtype"] == "bbox":

		#from listpoints_make import getRasterDims as dims
		#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
		print "[INFO]: Running TopoSUB"

		

		# for Ngrid in range(1,int(ncells)+1):
		# 	gridpath = wd +"/grid"+ str(Ngrid)

		# 	print "[INFO]: preparing surface layer " + str(Ngrid)
		# 	from domain_setup import makeSurface as surf # WARNING huge memory use (10GB)
		# 	surf.main(gridpath, config["modis"]["MODISdir"] )



		# from joblib import Parallel, delayed 
		# import multiprocessing 

		# def processInput(Ngrid): 
		# 			gridpath = wd +"/grid"+ str(Ngrid)

		# 			print "[INFO]: preparing surface layer " + str(Ngrid)
		# 			from domain_setup import makeSurface as surf 
		# 			surf.main(gridpath, config["modis"]["MODISdir"] )

		# 			print "[INFO]: running TopoSUB for grid " + str(Ngrid)
		# 			from toposub import toposub as tsub
		# 			tsub.main(gridpath, config["toposub"]["samples"])	 	

		# #if __name__ == '__main__': 
		# # what are your inputs, and what operation do you want to # perform on each input. For example... 
		# inputs = range(1,int(ncells)+1) 
		# num_cores = multiprocessing.cpu_count() 
		# results = Parallel(n_jobs=4)(delayed(processInput)(Ngrid) for Ngrid in inputs) 



		for Ngrid in range(1,int(ncells)+1):
			gridpath = wd +"/grid"+ str(Ngrid)

			print "[INFO]: preparing surface layer " + str(Ngrid)
			
			# make output directories if they dont exist
			ndvi_wd=gridpath + "/MODIS/NDVI"
			if not os.path.exists(ndvi_wd):
				os.makedirs(ndvi_wd)
#=========================================== NEW NDVI routine

			# compute from dem of small grid
			from getERA import getExtent as ext
			latN = ext.main(gridpath + "/predictors/ele.tif" , "latN")
			latS = ext.main(gridpath + "/predictors/ele.tif" , "latS")
			lonW = ext.main(gridpath + "/predictors/ele.tif" , "lonW")
			lonE = ext.main(gridpath + "/predictors/ele.tif" , "lonE")

			#need to run loop of five requests at set dates (can be fixed for now)
			mydates=["2000-08-12","2004-08-12","2008-08-12","2012-08-12","2016-08-12"]
			for date in mydates:
				# call bash script that does grep type stuff to update values in options file
				cmd = ["./DA/updateOptions.sh" , lonW , latS , lonE , latN , date , date, config["modis"]["options_file_NDVI"], ndvi_wd,config['modis']['tileX_start'] , config['modis']['tileX_end'] , config['modis']['tileY_start'] , config['modis']['tileY_end']]
				subprocess.check_output(cmd)

				# run MODIStsp tool
				from DA import getMODIS as gmod
				gmod.main("FALSE" , config["modis"]["options_file_NDVI"]) #  able to run non-interactively now

#=========================================== NEW NDVI routine


			from domain_setup import makeSurface as surf
			surf.main(gridpath, ndvi_wd )

			print "[INFO]: running TopoSUB for grid " + str(Ngrid)

			from toposub import toposub as tsub
			tsub.main(gridpath, config["toposub"]["samples"])	

else:
	print "[INFO]: TopoSUB already run"

#====================================================================
#	makeListpoint: creates a listpoints for each ERA-grid, only 
#	required for point runs. Removes Boxes that contain no points.
#====================================================================
if config["main"]["runtype"] == "points":

	
	#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")

	print "[INFO]: Setting up simulation directories for " + str(ncells)  + " ERA-Grids" 

	# set up sim directoroes #and write metfiles
	for Ngrid in range(1,int(ncells)+1):
		gridpath=wd +"/grid"+ str(Ngrid)

		print "[INFO]: preparing surface layer " + str(Ngrid)
		 
		# make output directories if they dont exist
		ndvi_wd=gridpath + "/MODIS/NDVI"
		if not os.path.exists(ndvi_wd):
			os.makedirs(ndvi_wd)

#=========================================== NEW NDVI routine

			# compute from dem of small grid
			from getERA import getExtent as ext
			latN = ext.main(gridpath + "/predictors/ele.tif" , "latN")
			latS = ext.main(gridpath + "/predictors/ele.tif" , "latS")
			lonW = ext.main(gridpath + "/predictors/ele.tif" , "lonW")
			lonE = ext.main(gridpath + "/predictors/ele.tif" , "lonE")

			#need to run loop of five requests at set dates (can be fixed for now)
			mydates=["2000-08-12","2004-08-12","2008-08-12","2012-08-12","2016-08-12"]
			for date in mydates:
				# call bash script that does grep type stuff to update values in options file
				cmd = ["./DA/updateOptions.sh" , lonW , latS , lonE , latN , date , date, config["modis"]["options_file_NDVI"], ndvi_wd,config['modis']['tileX_start'] , config['modis']['tileX_end'] , config['modis']['tileY_start'] , config['modis']['tileY_end']]
				subprocess.check_output(cmd)

				# run MODIStsp tool
				from DA import getMODIS as gmod
				gmod.main("FALSE" , config["modis"]["options_file_NDVI"]) #  able to run non-interactively now

#=========================================== NEW NDVI routine
		# runs makeSurface2.R now
		from domain_setup import makeSurface as surf
		surf.main(gridpath, ndvi_wd)

		print "[INFO]: creating listpoints for grid " + str(Ngrid)

		from listpoints_make import makeListpoints as list
		list.main(gridpath, config["main"]["pointsFile"],config["main"]["pkCol"], config["main"]["lonCol"], config["main"]["latCol"])

#====================================================================
#	run toposcale
#====================================================================
path=wd
file="tPoint.txt"
x=fileSearch.search(path, file)
if x != 1: #NOT ROBUST

	#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
	print "[INFO]: Running TopoSCALE"

	from toposcale import getGridEle as gele
	gele.main(wd)

	# set up sim directoroes #and write metfiles
	for Ngrid in range(1,int(ncells)+1):
		gridpath = wd +"/grid"+ str(Ngrid)

		if os.path.exists(gridpath):
			print "[INFO]: running toposcale for grid " + str(Ngrid)

			from toposcale import boxMetadata as box
			box.main(gridpath, str(Ngrid))

			from toposcale import tscale_plevel as plevel
			plevel.main(gridpath, str(Ngrid), "rhumPl")
			plevel.main(gridpath, str(Ngrid), "tairPl")
			plevel.main(gridpath, str(Ngrid), "uPl")
			plevel.main(gridpath, str(Ngrid), "vPl")

			from toposcale import tscale_sw as sw
			sw.main( gridpath, str(Ngrid), config["toposcale"]["swTopo"], config["main"]["tz"]) #TRUE requires svf as does more computes 

			from toposcale import tscale_lw as lw
			lw.main( gridpath, str(Ngrid), config["toposcale"]["svfCompute"]) #TRUE requires svf as computes terrain/sky effects
			
			from toposcale import tscale_p as p
			p.main( gridpath, str(Ngrid), config["toposcale"]["pfactor"])

		else:
			print "[INFO]: Grid "+ str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid)+1
else:
	print "[INFO]: TopoSCALE already run"

#====================================================================
#	DA
#====================================================================


#====================================================================
#	Setup Geotop simulations
#====================================================================

#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
print "[INFO]: Setup Geotop simulations" 

# set up sim directoroes #and write metfiles
#for Ngrid in range(1,int(ncells)+1):
	#gridpath = wd +"/grid"+ Ngrid

for Ngrid in grid_dirs:	
	gridpath = str(Ngrid)


	if os.path.exists(gridpath):
		print "[INFO]: Setting up geotop inputs " + str(Ngrid)

	 	print "[INFO]: Creating met files...."
	 	from gtop_setup import prepMet as met
		met.main(gridpath, config["toposcale"]["svfCompute"],config["da"]["tscale"],config["da"]["pscale"])


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
#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
print "[INFO]: Running LSM" 

# set up sim directoroes #and write metfiles
for Ngrid in grid_dirs:	
	gridpath = Ngrid

	if os.path.exists(gridpath):

	 	print "[INFO]: Simulations grid " + str(Ngrid) + " running (parallel model runs)"
		batchfile="batch.sh"

		sim_entries=gridpath +"/S*"

		f = open(batchfile, "w+")
		f.write("#!/bin/bash"+ "\n")
		f.write("cd " + config["geotop"]["lsmPath"] + "\n")
		f.write("parallel " + "./" + config["geotop"]["lsmExe"] + " ::: " + sim_entries + "\n")
		f.close()

		import os, sys, stat
		os.chmod(batchfile, stat.S_IRWXU)

		cmd     = ["./" + batchfile]
		subprocess.check_output( "./" + batchfile )

	else:
		print "[INFO]: " + str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid) + "+1"

#====================================================================
# Informed sampling
#====================================================================
if config["toposub"]["inform"] == "TRUE":
	print "[INFO]: Running Toposub INFORM!"

		# set up sim directoroes #and write metfiles
	for Ngrid in range(1,int(ncells)+1):
		gridpath = wd +"/grid"+ str(Ngrid)
		print gridpath
		from toposub import toposub_post1 as p1
		p1.main(gridpath ,config['toposub']['samples'] ,config['geotop']['file1'] ,config['geotop']['targV']) #TRUE requires svf as does more computes 

		from toposub import toposub_pre_inform as inform
		inform.main(gridpath , config['toposub']['samples'] , config['geotop']['targV'] , config['toposcale']['svfCompute']) #TRUE requires svf as does more computes 

	#====================================================================
	#	run toposcale INFORM!!
	#==================================================================

	#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
	print "[INFO]: Running TopoSCALE INFORM!"

	from toposcale import getGridEle as gele
	gele.main(wd)

	# set up sim directoroes #and write metfiles
	for Ngrid in range(1,int(ncells)+1):
		gridpath = wd +"/grid"+ str(Ngrid)

		if os.path.exists(gridpath):
			print "[INFO]: running toposcale for grid " + str(Ngrid)

			from toposcale import boxMetadata as box
			box.main(gridpath, str(Ngrid))

			from toposcale import tscale_plevel as plevel
			plevel.main(gridpath, str(Ngrid), "rhumPl")
			plevel.main(gridpath, str(Ngrid), "tairPl")
			plevel.main(gridpath, str(Ngrid), "uPl")
			plevel.main(gridpath, str(Ngrid), "vPl")

			from toposcale import tscale_sw as sw
			sw.main( gridpath, str(Ngrid), config["toposcale"]["swTopo"], config["main"]["tz"]) #TRUE requires svf as does more computes 

			from toposcale import tscale_lw as lw
			lw.main( gridpath, str(Ngrid), config["toposcale"]["svfCompute"]) #TRUE requires svf as does more computes terrain/sky effects
			
			from toposcale import tscale_p as p
			p.main( gridpath, str(Ngrid), config["toposcale"]["pfactor"])

		else:
			print "[INFO]: Grid "+ str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid)+1
	


	#====================================================================
	#	Setup Geotop simulations INFORM!!
	#====================================================================

	#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
	print "[INFO]: Setup Geotop simulations INFORM!" 

	# set up sim directoroes #and write metfiles
	#for Ngrid in range(1,int(ncells)+1):
		#gridpath = wd +"/grid"+ Ngrid

	for Ngrid in grid_dirs:	
		gridpath = str(Ngrid)


		if os.path.exists(gridpath):
			print "[INFO]: Setting up geotop inputs " + str(Ngrid)

		 	print "[INFO]: Creating met files...."
		 	from gtop_setup import prepMet as met
			met.main(gridpath, config["toposcale"]["svfCompute"],config["da"]["tscale"],config["da"]["pscale"])


			print "[INFO]: extract surface properties"
			from gtop_setup import pointsSurface as psurf
			psurf.main(gridpath)

			print "[INFO]: making inputs file"
			from gtop_setup import makeGeotopInputs as gInput
			gInput.main(gridpath, config["geotop"]["geotopInputsPath"], config["main"]["startDate"], config["main"]["endDate"])

		else:
			print "[INFO]: " + str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid) + "+1"


	#====================================================================
	#	Run LSM INFORM!!
	#====================================================================
	#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
	print "[INFO]: Running LSM INFORM!" 

	# set up sim directoroes #and write metfiles
	for Ngrid in grid_dirs:	
		gridpath = Ngrid

		if os.path.exists(gridpath):

		 	print "[INFO]: Simulations grid" + str(Ngrid) + " running (parallel model runs)"
			batchfile="batch.sh"

			sim_entries=gridpath +"/S*"

			f = open(batchfile, "w+")
			f.write("#!/bin/bash"+ "\n")
			f.write("cd " + config["geotop"]["lsmPath"] + "\n")
			f.write("parallel " + "./" + config["geotop"]["lsmExe"] + " ::: " + sim_entries + "\n")
			f.close()

			import os, sys, stat
			os.chmod(batchfile, stat.S_IRWXU)

			cmd     = ["./" + batchfile]
			subprocess.check_output( "./" + batchfile )

		else:
			print "[INFO]: " + str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid) + "+1"











#====================================================================
#	Spatialise toposub results SIMULATION MEAN
#====================================================================
if config["main"]["runtype"] == "bbox":

	print "[INFO]: Spatialising TopoSUB results...."

	for Ngrid in grid_dirs:	
		gridpath = str(Ngrid)
		print "[INFO]: running spatialisation routines for grid " + str(Ngrid)
		from toposub import toposub_post2 as post2
		post2.main(gridpath, config["toposub"]["samples"],config["geotop"]["file1"],config["geotop"]["targV"],config["main"]["startDate"],config["main"]["endDate"] )	


#====================================================================
#	Spatialise toposub results LATEST
#====================================================================
if config["main"]["runtype"] == "bbox":

	print "[INFO]: Spatialising TopoSUB results...."

	for Ngrid in grid_dirs:	
		gridpath = str(Ngrid)

		print "[INFO]: running spatialisation routines for grid " + str(Ngrid)
		from toposub import toposub_postInstant as postInst
		postInst.main(gridpath, config["toposub"]["samples"],config["geotop"]["file1"],config["geotop"]["targV"] )	

#====================================================================
#	Averaged coarse grid timeseries of toposub results 
#====================================================================
if config["main"]["runtype"] == "bbox":

	print "[INFO]: Making coarse grid timeseries TopoSUB results...."

	for Ngrid in grid_dirs:	
		gridpath = str(Ngrid)

		print "[INFO]: running timeseries routines for grid " + str(Ngrid)
		from toposub import toposub_gridTS as gts
		gts.main(gridpath, config["toposub"]["samples"],config["geotop"]["file1"],config["geotop"]["targV"] )	

#====================================================================
#	Give pdf of toposub results
#====================================================================
#if config["main"]["runtype"] == "bbox":	
# if config["main"]["runtype"] == "bbox":

# 	print "Spatialising toposub results...."

# 	for Ngrid in range(1,int(ncells)+1):
# 		gridpath = wd +"/grid"+ Ngrid


# 		print "running spatialisation routines for grid " + Ngrid
# 		from toposub import toposub_post1 as post1
# 		post1.main(gridpath, config["toposub"]["samples"],config["geotop"]["file1"],config["geotop"]["targV"] )	

#====================================================================
#	Get MODIS SCA
#====================================================================

if config["modis"]["getMODISSCA"] == "TRUE":
	for Ngrid in grid_dirs:	
		gridpath = str(Ngrid)


		if os.path.exists(gridpath):

			# set up directory
			sca_wd=gridpath + "/MODIS/SC"
			if not os.path.exists(sca_wd):
				os.makedirs(sca_wd)
#====================================================================
#	Points
#====================================================================
			if config["main"]["runtype"] == "points":
				# clear data
				# import os, shutil
				# folder = config["modis"]["sca_wd"]
				# for the_file in os.listdir(folder):
				#     file_path = os.path.join(folder, the_file)
				#     try:
				#         if os.path.isfile(file_path):
				#             os.unlink(file_path)
				#         elif os.path.isdir(file_path): shutil.rmtree(file_path)
				#     except Exception as e:
				#         print(e)

				# compute from dem of small grid
				from getERA import getExtent as ext
				latN = ext.main(gridpath + "/predictors/ele.tif" , "latN")
				latS = ext.main(gridpath + "/predictors/ele.tif" , "latS")
				lonW = ext.main(gridpath + "/predictors/ele.tif" , "lonW")
				lonE = ext.main(gridpath + "/predictors/ele.tif" , "lonE")

				# call bash script that does grep type stuff to update values in options file
				cmd = ["./DA/updateOptions.sh" , lonW , latS , lonE , latN , config["main"]["startDate"] , config["main"]["endDate"] , config["modis"]["options_file_SCA"], sca_wd, config['modis']['tileX_start'] , config['modis']['tileX_end'] , config['modis']['tileY_start'] , config['modis']['tileY_end']]
				subprocess.check_output( cmd)

				# run MODIStsp tool
				from DA import getMODIS as gmod
				gmod.main("FALSE" , config["modis"]["options_file_SCA"]) #  able to run non-interactively now

				# extract timersies per point
				from DA import scaTS
				scaTS.main(gridpath ,sca_wd + "/Snow_Cov_Daily_500m_v5/SC" ,wd + "/spatial/points.shp" )

				# POSTPROCESS FSCA FILES TO FILL GAPS (linearly interpolate)



#====================================================================
#	bbox
#====================================================================
			if config["main"]["runtype"] == "bbox":
				

				# clear data: MAKE SWITCH FOR THIS

				# import os, shutil
				# folder = config["modis"]["sca_wd"]
				# for the_file in os.listdir(folder):
				#     file_path = os.path.join(folder, the_file)
				#     try:
				#         if os.path.isfile(file_path):
				#             os.unlink(file_path)
				#         elif os.path.isdir(file_path): shutil.rmtree(file_path)
				#     except Exception as e:
				#         print(e)

				# compute from dem
				from getERA import getExtent as ext
				latN = ext.main(gridpath + "/predictors/ele.tif" , "latN")
				latS = ext.main(gridpath + "/predictors/ele.tif" , "latS")
				lonW = ext.main(gridpath + "/predictors/ele.tif" , "lonW")
				lonE = ext.main(gridpath + "/predictors/ele.tif" , "lonE")

				# call bash script that does grep type stuff to update values in options file
				cmd = ["./DA/updateOptions.sh" , lonW , latS , lonE , latN , config["main"]["startDate"] , config["main"]["endDate"] , config["modis"]["options_file_SCA"],sca_wd, config['modis']['tileX_start'] , config['modis']['tileX_end'] , config['modis']['tileY_start'] , config['modis']['tileY_end']]
				subprocess.check_output( cmd)

				# run MODIStsp tool
				from DA import getMODIS as gmod
				gmod.main("FALSE" , config["modis"]["options_file_SCA"]) #  able to run non-interactively now

				# extract timersies per point
				from DA import scaTS_GRID
				scaTS_GRID.main(gridpath ,sca_wd + "/Snow_Cov_Daily_500m_v5/SC" )

				# POSTPROCESS FSCA FILES TO FILL GAPS (linearly interpolate)

else:
	print "[INFO]: No MODIS SCA retrieved"


#====================================================================
#	Retrive latest sentinel 2
#====================================================================
#https://www.evernote.com/Home.action#n=e77ce355-1b1e-4a89-896b-4036f905dfea&ses=1&sh=5&sds=5&x=sentinel&

print("[INFO]: %f minutes for run" % round((time.time()/60 - start_time/60),2))



			#====================================================================
			#	Get MODIS SCA for a given date
			#====================================================================
			# if config["main"]["runtype"] == "bbox":
			# 	# clear data
			# 	import os, shutil
			# 	folder = config["modis"]["sca_wd"]
			# 	for the_file in os.listdir(folder):
			# 	    file_path = os.path.join(folder, the_file)
			# 	    try:
			# 	        if os.path.isfile(file_path):
			# 	            os.unlink(file_path)
			# 	        elif os.path.isdir(file_path): shutil.rmtree(file_path)
			# 	    except Exception as e:
			# 	        print(e)

			# 	# compute from dem
			# 	from getERA import getExtent as ext
			# 	latN = ext.main(wd + "/predictors/ele.tif" , "latN")
			# 	latS = ext.main(wd + "/predictors/ele.tif" , "latS")
			# 	lonW = ext.main(wd + "/predictors/ele.tif" , "lonW")
			# 	lonE = ext.main(wd + "/predictors/ele.tif" , "lonE")

			# 	# call bash script that does grep type stuff to update values in options file
			# 	cmd = ["./DA/updateOptions.sh" , lonW , latS , lonE , latN , config["main"]["endDate"] , config["main"]["endDate"] , config["modis"]["options_file"]]
			# 	subprocess.check_output( cmd)

			# 	# run MODIStsp tool
			# 	from DA import getMODIS as gmod
			# 	gmod.main("FALSE" , config["modis"]["options_file"]) #  able to run non-interactively now

			# 	# compare obs to mod

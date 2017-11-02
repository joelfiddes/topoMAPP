#!/usr/bin/env python

"""
INI file should be configured named and supplied as argument of fullpathtofile or just filename if in curent wd eg: 
		
		$ python writeConfig.py

		$ python topomapp_main.py test.ini &> test.log
"""

import sys
import os
import subprocess
import logging
import os.path
from listpoints_make import getRasterDims as dims
import glob
import joblib




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
wd = config["main"]["wd"]

#====================================================================
#	Creat wd dir if doesnt exist
#====================================================================
#directory = os.path.dirname(wd)
if not os.path.exists(wd):
	os.makedirs(wd)


#====================================================================
#	Logging
#====================================================================

logging.basicConfig(level=logging.DEBUG, filename=wd+"/logfile", filemode="a+",
                        format="%(asctime)-15s %(levelname)-8s %(message)s")

#====================================================================
#	Announce wd
#====================================================================
logging.info("[INFO]: Simulation directory:" + wd  )

#====================================================================
#	Initialise run: this can be used to copy meteo and surfaces to a new sim directory. 
# 	Main application is in ensemble runs
#====================================================================
if config["main"]["initSim"] == "TRUE":
	import TMinit
	TMinit.main(config, ensembRun=False)

  
#====================================================================
# Copy config to simulation directory
#==================================================================== 
configfilename = os.path.basename(sys.argv[1])

config.filename = wd +  "/" + configfilename
config.write()

#====================================================================
#	Setup domain
#====================================================================

# control statement to skip if "asp.tif" exist - indicator fileNOT ROBUST
fname = wd + "/predictors/asp.tif"
if os.path.isfile(fname) == False:		

		# copy preexisting dem
	if config["main"]["demexists"] == "TRUE":

		cmd = "mkdir " + wd + "/predictors/"
		os.system(cmd)
		src = config["main"]["dempath"]
		dst = wd +"/predictors/dem.tif"
		cmd = "cp -r %s %s"%(src,dst)
		os.system(cmd) 

	from domain_setup import getDEM2 as gdem
	gdem.main(wd ,config["main"]["demDir"] ,config["era-interim"]["domain"], config["main"]["shp"])

	from domain_setup import makeKML as kml
	kml.main(wd, wd + "/predictors/ele.tif", "shape", wd + "/spatial/extent")	      
	kml.main(wd, wd + "/spatial/eraExtent.tif", "raster", wd + "/spatial/eraExtent")
	#kml.main(wd, wd + "/spatial/extentRequest.shp", "raster", wd + "/spatial/extentRequest")

	from domain_setup import computeTopo as topo
	topo.main(wd, config["toposcale"]["svfCompute"])

else:
	logging.info("[INFO]: topo predictors precomputed")
#====================================================================
#	GET ERA
#====================================================================

fname1 = wd + "/eraDat/SURF.nc"
fname2 = wd + "/eraDat/PLEVEL.nc"
if os.path.isfile(fname2) == False and os.path.isfile(fname2) == False: #NOT ROBUST

	# set ccords to those of downloaded dem extent
	#if config["main"]["runtype"] == "points":
	from getERA import getExtent as ext
	latN = ext.main(wd + "/predictors/ele.tif" , "latN")
	latS = ext.main(wd + "/predictors/ele.tif" , "latS")
	lonW = ext.main(wd + "/predictors/ele.tif" , "lonW")
	lonE = ext.main(wd + "/predictors/ele.tif" , "lonE")

	config["main"]["latn"]  = latN
	config["main"]["lats"]  = latS
	config["main"]["lonw"]  = lonW
	config["main"]["lone"]  = lonE

	eraDir = wd + "/eraDat"
	if not os.path.exists(eraDir):
		os.mkdir(eraDir)


	from getERA import eraRetrievePLEVEL_pl as plevel
	logging.info( "Retrieving ECWMF pressure-level data")
	#plevel.retrieve_interim( config["main"]["startDate"], config["main"]["endDate"], latN, latS, lonE, lonW, config["era-interim"]["grid"],eraDir, config["era-interim"]["dataset"] )
	plevel.retrieve_interim( config, eraDir  , latN, latS, lonE, lonW)	

	from getERA import eraRetrieveSURFACE_pl as surf
	logging.info( "Retrieving ECWMF surface data")
	#surf.retrieve_interim(config["main"]["startDate"], config["main"]["endDate"], latN, latS, lonE, lonW, config["era-interim"]["grid"],eraDir, config["era-interim"]["dataset"] )
	surf.retrieve_interim( config, eraDir  , latN, latS, lonE, lonW)	

	# Merge NC timeseries (requires linux package cdo)
	import subprocess
	#os.chdir(eraDir)
	cmd     = "cdo -b F64 -f nc2 mergetime " + wd + "/eraDat/interim_daily_PLEVEL* " +  wd + "/eraDat/PLEVEL.nc"

	if os.path.exists(wd + "eraDat/PLEVEL.nc"):
	    os.remove(wd + "eraDat/PLEVEL.nc")
	    logging.info( "removed original PLEVEL.nc")

	logging.info("Running:" + str(cmd))
	subprocess.check_output(cmd, shell = "TRUE")

	cmd     = "cdo -b F64 -f nc2 mergetime " + wd +  "/eraDat/interim_daily_SURF* " + wd +"/eraDat/SURF.nc"

	if os.path.exists(wd + "eraDat/SURF.nc"):
	    os.remove(wd + "eraDat/SURF.nc")
	    logging.info( "removed original SURF.nc" )

	logging.info("[INFO]: Running:" + str(cmd))
	subprocess.check_output(cmd, shell = "TRUE")

else:
	logging.info( "[INFO]: SURF.nc and PLEVEL.nc precomputed" )

	#os.chdir(config["main"]["srcdir"])

if config["era-interim"]["dataset"] == "interim":
	from getERA import era_prep as prep
	prep.main(wd, config["main"]["startDate"], config["main"]["endDate"])

if config["era-interim"]["dataset"] == "era5":
	from getERA import era_prep2 as prep
	prep.main(wd, config["main"]["startDate"], config["main"]["endDate"])
#====================================================================
#	Prepare simulation directories - grid
#====================================================================

# check if sim directories already exist
grid_dirs = glob.glob(wd +"/grid*")
if len(grid_dirs) < 1:

	if config["main"]["initSim"] != "TRUE":
		from getERA import prepSims as sim
		sim.main(wd)

	# define ncells here based on occurances of grid* directoriers created by prepSims or copied if initSim == True
	grid_dirs = glob.glob(wd +"/grid*")
	ncells = len(grid_dirs)
	logging.info( "[INFO]: This simulation contains ", ncells, " grids" )
	logging.info( "[INFO]: grids to be computed " + str(grid_dirs) )

	#====================================================================
	#	Loop through grids - prepare sims and remove grids not containing 
	# 	points (buffer)
	#====================================================================
	if config["main"]["runtype"] == "points":
		
		for Ngrid in range(1,int(ncells)+1):
			
			gridpath = wd +"/grid"+ str(Ngrid)

			logging.info( "[INFO]: creating listpoints for grid " + str(Ngrid) )

			from listpoints_make import makeListpoints as list
			list.main(gridpath, config["main"]["shp"])

		# re define ncells here based on occurances of grid* directoriers after removals
		grid_dirs = glob.glob(wd +"/grid*")
		ncells = len(grid_dirs)
		logging.info( "[INFO]: This simulation now contains ", ncells, " grids" )
		logging.info( "[INFO]: grids to be computed " + str(grid_dirs) )

#====================================================================
#	Create MODIS dir for NDVI at wd level
#====================================================================

# make output directory at wd level so grids can share hdf scenes if overlap - save download time
# in contrast sca is saved to gridpath and hdf not retained due to volume of files
ndvi_wd=wd + "/MODIS/NDVI"
if not os.path.exists(ndvi_wd):
	os.makedirs(ndvi_wd)

#====================================================================
#	Start main Ngrid loop
#====================================================================

# start main grid loop here - make parallel here
# need config to prioritise grids here
logging.info("Grids to loop over = ")
logging.info( grid_dirs )

for Ngrid in grid_dirs:
	gridpath = Ngrid

	# skip to next iteratyion if results exist
	fname1 = gridpath + "/groundResults"
	fname2 = gridpath + "/surfaceResults"
	if os.path.isfile(fname2) == True and os.path.isfile(fname2) == True:
		logging.info( "[INFO]: Results already exist for " + Ngrid +" skipping to next grid" )
		continue

	logging.info( "[INFO]: COMPUTING GRID: " + Ngrid )
#====================================================================
#	Compute svf here
#====================================================================
	if config['toposcale']['svfCompute'] == 'TRUE':
		from domain_setup import computeSVF
		computeSVF.main(gridpath, angles=str(6), dist=str(500))
#====================================================================
#	Download MODIS NDVI here
#====================================================================
	# only run if surface tif doesnt exist
	fname = gridpath + "/predictors/surface.tif"
	if os.path.isfile(fname) == False:

		logging.info( "[INFO]: preparing surface layer " + Ngrid )
		
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

		from domain_setup import makeSurface as surf
		surf.main(gridpath, ndvi_wd )

#====================================================================
#	Run bbox script
#====================================================================
	if config["main"]["runtype"] == "bbox":
		import TMgrid
		TMgrid.main(wd, Ngrid, config)

#====================================================================
#	Run points script
#====================================================================

# make into proper modules with arguments etc
# import config and Ngrid
	if config["main"]["runtype"] == "points":
		import TMpoints
		TMpoints.main(wd, Ngrid, config)

#====================================================================
#	Aggregate results and clean up
#====================================================================
	from topoResults import resultsCube
	resultsCube.main(Ngrid)

#====================================================================
#	Run ensemble
#====================================================================
	# if config["ensemble"]["run"] == "TRUE":
	# 	import ensembleRun
	# 	ensembleRun.main(config)

#====================================================================
#	Run DA
#====================================================================
	#if config["main"]["mode"] == "da":
		#import TMensemble.py
		#import TMda.py

#====================================================================
#	Polat plot
#====================================================================
	# src = "./rsrc/polarPlot.R"
	# dst = gridpath
	# cmd = "Rscript %s %s"%(src,dst)
	# os.system(cmd)




logging.info("[INFO]: %f minutes for run" % round((time.time()/60 - start_time/60),2) )






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
#	Initial checks
#====================================================================
# name = raw_input("Working directory is: " + config["main"]["wd"])
# print "OK"

# name = raw_input("Runtype is: " + config["main"]["runtype"])
# print "OK"

# name = raw_input("tscaleOnly: " + config["toposcale"]["tscaleOnly"])
# print "OK"

# name = raw_input("Start date is: " + config["main"]["startdate"])
# print "OK"

# name = raw_input("End date is: " + config["main"]["enddate"])
# print "OK"

# name = raw_input("Reanalysis is: " + config['era-interim']['dataset'])
# print "OK"

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
logging.info("----------------------- START RUN -----------------------")
logging.info("Simulation directory: " + wd  )
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
	logging.info("Retrieve DEM")
	gdem.main(wd ,config["main"]["demDir"] ,config["era-interim"]["domain"], config["main"]["shp"])

	from domain_setup import makeKML as kml
	logging.info("Generate extent files")
	kml.main(wd, wd + "/predictors/ele.tif", "shape", wd + "/spatial/extent")	      
	kml.main(wd, wd + "/spatial/eraExtent.tif", "raster", wd + "/spatial/eraExtent")
	#kml.main(wd, wd + "/spatial/extentRequest.shp", "raster", wd + "/spatial/extentRequest")

	from domain_setup import computeTopo as topo
	logging.info("Compute topo predictors")
	topo.main(wd, config["toposcale"]["svfCompute"])

else:
	logging.info("Topo predictors computed")
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
	cmd     = "cdo -b F64 -f nc2 mergetime " + wd + "/eraDat/PLEVEL* " +  wd + "/eraDat/PLEVEL.nc"

	if os.path.exists(wd + "eraDat/PLEVEL.nc"):
	    os.remove(wd + "eraDat/PLEVEL.nc")
	    logging.info( "removed original PLEVEL.nc")

	logging.info("Running:" + str(cmd))
	subprocess.check_output(cmd, shell = "TRUE")

	cmd     = "cdo -b F64 -f nc2 mergetime " + wd +  "/eraDat/SURF* " + wd +"/eraDat/SURF.nc"

	if os.path.exists(wd + "eraDat/SURF.nc"):
	    os.remove(wd + "eraDat/SURF.nc")
	    logging.info( "removed original SURF.nc" )

	logging.info(" Running:" + str(cmd))
	subprocess.check_output(cmd, shell = "TRUE")

else:
	logging.info( "ERA data retrieved" )

	#os.chdir(config["main"]["srcdir"])

#====================================================================
#	Preprocess ERA
#====================================================================
fname1 = wd + "/eraDat/all/tSurf" # check for last file gerenrated by era_prep script
if os.path.isfile(fname1) == False: 

	logging.info("Preprocessing ERA data")

	if config["era-interim"]["dataset"] == "interim":
		from getERA import era_prep as prep
		prep.main(wd, config["main"]["startDate"], config["main"]["endDate"])

	if config["era-interim"]["dataset"] == "era5":
		from getERA import era_prep2 as prep
		prep.main(wd, config["main"]["startDate"], config["main"]["endDate"])
else:
	logging.info( "ERA data processed")
#====================================================================
#	Prepare simulation directories - grid
#====================================================================

# check if sim directories already exist
grid_dirs = glob.glob(wd +"/grid*")
if len(grid_dirs) < 1:

	if config["main"]["initSim"] != "TRUE":
		logging.info( "initialising simulation directories")
		from getERA import prepSims as sim
		sim.main(wd)

	# define ncells here based on occurances of grid* directoriers created by prepSims or copied if initSim == True
	grid_dirs = glob.glob(wd +"/grid*")
	ncells = len(grid_dirs)

else:
	logging.info( "Simulation directories initialised")
#====================================================================
#	Create MODIS dir for NDVI at wd level
#====================================================================

# make output directory at wd level so grids can share hdf scenes if overlap - save download time
# in contrast sca is saved to gridpath and hdf not retained due to volume of files
ndvi_wd=wd + "/MODIS/NDVI"
if not os.path.exists(ndvi_wd) and config["toposcale"]["tscaleOnly"] == "FALSE" :
	os.makedirs(ndvi_wd)

#====================================================================
#	Start main Ngrid loop
#====================================================================

# start main grid loop here - make parallel here
# need config to prioritise grids here
logging.info("Grids to loop over = ")
logging.info( [os.path.basename(os.path.normpath(x)) for x in grid_dirs] )

for Ngrid in grid_dirs:
	gridpath = Ngrid

	# skip to next iteration if results exist
	fname1 = gridpath + "/RUNSUCCESS"
	#fname2 = gridpath + "/surfaceResults"
	if os.path.isfile(fname1) == True: #and os.path.isfile(fname2) == True:
		logging.info( "Results already exist (RUNSUCCESS file found) for " + Ngrid +" skipping to next grid" )
		
		continue

	logging.info( "")
	logging.info( "----- NOW COMPUTING GRID: " + os.path.basename(os.path.normpath(Ngrid)) + "-----")
#====================================================================
#	Does grid contain points?
#====================================================================
 	if config['main']['runtype'] == "points":
		from listpoints_make import findGridsWithPoints
		numPoints = findGridsWithPoints.main(wd, gridpath + "/predictors/ele.tif" , config["main"]["shp"])
		if(len(numPoints) == 0):
			logging.info( "Grid box contains no points, skip to next grid and remove: " + Ngrid)
			import shutil
			shutil.rmtree(gridpath)
			continue

# more elegant to define new grid_dirs based on this analysis but hard to pass output of Rscript in python. len9nuPoints) counts characters so while ==0 tells us no point is present > 0 does not tell us how many points there are.
#====================================================================
#	Compute svf here
#====================================================================
	if config['toposcale']['svfCompute'] == 'TRUE':

		logging.info( "Calculating SVF layer: " + os.path.basename(os.path.normpath(Ngrid)) )

		from domain_setup import computeSVF
		computeSVF.main(gridpath, angles=str(6), dist=str(500))

#====================================================================
#	Download MODIS NDVI
#
#   NDVI (in contrast to SCA) is run within the Ngrid loop and HDF 
#	are saved so multiple downloads NOT required. Data volume is low so 
#	this is OK. This allows faster completion of each grid and permits 
#	scalable application of the analysis algorithms on limited size domain.
#====================================================================
	# only run if surface tif doesnt exist
	fname = gridpath + "/predictors/surface.tif"
	if os.path.isfile(fname) == False and config["toposcale"]["tscaleOnly"] == "FALSE":

		logging.info( "Preparing land surface layer from MODIS: " + os.path.basename(os.path.normpath(Ngrid)) )

		# Define grid AOI shp
		gridAOI = gridpath + "/extent.shp"
		cmd = ["Rscript", "./rsrc/rst2shp.R" , gridpath + "/predictors/ele.tif", gridAOI]
		subprocess.check_output(cmd)

		#need to run loop of five requests at set dates (can be fixed for now)
		mydates=["2001-08-12","2004-08-12","2008-08-12","2012-08-12"]#,"2016-08-12"]
		for date in mydates:
			# call bash script that does grep type stuff to update values in options file
			cmd = ["./DA/updateOptions.sh" , date , date, config["modis"]["options_file_NDVI"], ndvi_wd]
			subprocess.check_output(cmd)

			# run MODIStsp tool
			from DA import getMODIS as gmod
			gmod.main(config["modis"]["options_file_NDVI"], gridAOI) #  able to run non-interactively now

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

	if config["main"]["runtype"] == "points":
		
		import TMpoints
		TMpoints.main(wd, Ngrid, config)

#====================================================================
#	Aggregate results if tscaleOnly == FALSE
#====================================================================
	
	#This doesent scale so well, not used yet, but would be nice!
	
	#if config["toposcale"]["tscaleOnly"] == "FALSE":
		
		#from topoResults import resultsCube
		#resultsCube.main(Ngrid)

#====================================================================
#	Run SCA here for entire domain to make efficient in terms of 
#	no duplicate hdf downloads
#====================================================================

if config["modis"]["getMODISSCA"] == "TRUE" and config["toposcale"]["tscaleOnly"] == "FALSE":

	logging.info( "Retrieving MODIS SCA for entire domain" )

	inRst = wd + "/spatial/eraExtent.tif"
	outShp = wd + "/spatial/eraExtent.shp"
	cmd = ["Rscript", "./rsrc/rst2shp.R" , inRst, outShp]
	subprocess.check_output(cmd)

	import TMsca
	TMsca.main(config, shp = outShp )




#====================================================================
#	Post-process SCA
#====================================================================
	for Ngrid in grid_dirs:
		gridpath = Ngrid
		logging.info( "Postprocessing MODIS SCA : " + os.path.basename(os.path.normpath(Ngrid)) )

	# Does grid contain points?
	 	if config['main']['runtype'] == "points":
			from listpoints_make import findGridsWithPoints
			numPoints = findGridsWithPoints.main(wd, gridpath + "/predictors/ele.tif" , config["main"]["shp"])
			if(len(numPoints) == 0):
				logging.info( "Grid box contains no points, skip to next grid")
				continue

		if config['main']['runtype'] == "points":
			# extract timersies per point
			logging.info( "Process MODIS SCA: " + os.path.basename(os.path.normpath(Ngrid)) )	
			from DA import scaTS
			scaTS.main(gridpath ,sca_wd + "/Snow_Cov_Daily_500m_v5/SC" ,config['main']['shp'] )

		if config['main']['runtype'] == "bbox":
			logging.info( "Process MODIS SCA: " + os.path.basename(os.path.normpath(Ngrid)) )
			from DA import scaTS_GRID
			scaTS_GRID.main(gridpath ,sca_wd + "/Snow_Cov_Daily_500m_v5/SC" )

else:
	logging.info( "No MODIS SCA retrieved" )
#====================================================================
#	Run ensemble
#====================================================================
if config["ensemble"]["run"] == "TRUE":
	import ensembleRun
	ensembleRun.main(config)

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



logging.info("Simulation finished!")
logging.info(" %f minutes for total run" % round((time.time()/60 - start_time/60),2) )






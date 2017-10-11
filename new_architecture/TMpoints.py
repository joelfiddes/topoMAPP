#!/usr/bin/env python
import sys
import os
import subprocess
import logging
import os.path
from listpoints_make import getRasterDims as dims
import glob


#====================================================================
#	makeListpoint: creates a listpoints for each ERA-grid, only 
#	required for point runs. Removes Boxes that contain no points.
#====================================================================

#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")

print "[INFO]: Setting up simulation directories for " + ncells  + " ERA-Grids" 

# set up sim directoroes #and write metfiles
for Ngrid in range(1,int(ncells)+1):
	gridpath=wd +"/grid"+ str(Ngrid)

	print "[INFO]: preparing surface layer " + str(Ngrid)
	 
	# make output directories if they dont exist
	ndvi_wd=gridpath + "/MODIS/NDVI"
	if not os.path.exists(ndvi_wd):
		os.makedirs(ndvi_wd)

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

	# runs makeSurface2.R now
	from domain_setup import makeSurface as surf
	surf.main(gridpath, ndvi_wd)

	print "[INFO]: creating listpoints for grid " + str(Ngrid)

	from listpoints_make import makeListpoints as list
	list.main(gridpath, config["main"]["pointsFile"],config["main"]["pkCol"], config["main"]["lonCol"], config["main"]["latCol"])

#====================================================================
#	run toposcale
#====================================================================
import TMtoposcale

#====================================================================
#	setup and run simulations
#====================================================================
import TMsim.py

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

else:
	print "[INFO]: No MODIS SCA retrieved"








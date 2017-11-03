#!/usr/bin/env python
import sys
import os
import subprocess
import logging
import os.path
from listpoints_make import getRasterDims as dims
import glob


def main(wd, Ngrid, config):
	#====================================================================
	#	ompute listpoints and remove grids not containing 
	# 	points (buffer)
	#====================================================================		
	logging.info( "Making listpoints" + os.path.basename(os.path.normpath(Ngrid)) )
	from listpoints_make import makeListpoints as list
	list.main(str(Ngrid), config["main"]["shp"])


	#====================================================================
	#	run toposcale
	#====================================================================
	logging.info( "TopoSCALE" + os.path.basename(os.path.normpath(Ngrid)) )
	import TMtoposcale
	TMtoposcale.main(wd, Ngrid, config)

	#====================================================================
	#	setup and run simulations
	#====================================================================
	logging.info( "GeoTOP setup and run" + os.path.basename(os.path.normpath(Ngrid)) )
	import TMsim
	TMsim.main(Ngrid, config)

	#====================================================================
	#	Get MODIS SCA
	#====================================================================

	if config["modis"]["getMODISSCA"] == "TRUE":
			
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
			logging.info( "Fetch MODIS SCA " + os.path.basename(os.path.normpath(Ngrid)) )	
			from DA import getMODIS as gmod
			gmod.main("FALSE" , config["modis"]["options_file_SCA"]) #  able to run non-interactively now

			# extract timersies per point
			logging.info( "Process MODIS SCA " + os.path.basename(os.path.normpath(Ngrid)) )	
			from DA import scaTS
			scaTS.main(gridpath ,sca_wd + "/Snow_Cov_Daily_500m_v5/SC" ,wd + "/spatial/points.shp" )

			# POSTPROCESS FSCA FILES TO FILL GAPS (linearly interpolate)

	else:
		print "[INFO]: No MODIS SCA retrieved"


# calling main
if __name__ == '__main__':
	import sys
	wd          = sys.argv[1]
	Ngrid      = sys.argv[2]
	config      = sys.argv[3]
	main(wd, Ngrid, config)





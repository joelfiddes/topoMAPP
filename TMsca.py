#!/usr/bin/env python
import os
import os.path
import logging
import subprocess

def main(Ngrid, config):

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


		if config['main']['runtype'] == "points":
			# extract timersies per point
			logging.info( "Process MODIS SCA: " + os.path.basename(os.path.normpath(Ngrid)) )	
			from DA import scaTS
			scaTS.main(gridpath ,sca_wd + "/Snow_Cov_Daily_500m_v5/SC" ,config['main']['shp'] )

		if config['main']['runtype'] == "bbox":
			logging.info( "Process MODIS SCA: " + os.path.basename(os.path.normpath(Ngrid)) )
			from DA import scaTS_GRID
			scaTS_GRID.main(gridpath ,sca_wd + "/Snow_Cov_Daily_500m_v5/SC" )


# calling main
if __name__ == '__main__':
	import sys
	Ngrid      = sys.argv[1]
	config      = sys.argv[2]
	main(Ngrid, config)
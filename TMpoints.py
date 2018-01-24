#!/usr/bin/env python
import sys
import os
import subprocess
import logging
import os.path
from listpoints_make import getRasterDims as dims
import glob


def main(wd, Ngrid, config):

	# define grid
	gridpath = str(Ngrid)

	#====================================================================
	#	ompute listpoints and remove grids not containing 
	# 	points (buffer)
	#====================================================================		
	logging.info( "Making listpoints: " + os.path.basename(os.path.normpath(Ngrid)) )
	from listpoints_make import makeListpoints as list
	list.main(str(Ngrid), config["main"]["shp"])


	#====================================================================
	#	run toposcale
	#====================================================================


 	fname1 = gridpath + "/tPoint.txt"
 	fname2 = gridpath + "/rPoint.txt"
 	fname3 = gridpath + "/uPoint.txt"
 	fname4 = gridpath + "/vPoint.txt"
 	fname5 = gridpath + "/lwPoint.txt"
 	fname6 = gridpath + "/sol.txt"
 	fname7 = gridpath + "/pSurf_lapse.txt"
	
	if os.path.isfile(fname1) == True and os.path.isfile(fname2) == True and os.path.isfile(fname3) == True and os.path.isfile(fname4) == True and os.path.isfile(fname5) == True and os.path.isfile(fname6) == True and os.path.isfile(fname7) == True: #NOT ROBUST
		
		logging.info( "TopoSCALE already run: " + os.path.basename(os.path.normpath(Ngrid)) )
	
	else:

		logging.info( "TopoSCALE: " + os.path.basename(os.path.normpath(Ngrid)) )
		import TMtoposcale
		TMtoposcale.main(wd, Ngrid, config)

	#====================================================================
	#	setup and run simulations
	#====================================================================
	if config["toposcale"]["tscaleOnly"] == "FALSE":
		logging.info( "GeoTOP setup and run: " + os.path.basename(os.path.normpath(Ngrid)) )
		import TMsim
		TMsim.main(Ngrid, config)

# calling main
if __name__ == '__main__':
	import sys
	wd          = sys.argv[1]
	Ngrid      = sys.argv[2]
	config      = sys.argv[3]
	main(wd, Ngrid, config)





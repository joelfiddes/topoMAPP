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
	if os.path.isfile(fname1) == False: #NOT ROBUST
		logging.info( "TopoSCALE: " + os.path.basename(os.path.normpath(Ngrid)) )
		import TMtoposcale
		TMtoposcale.main(wd, Ngrid, config)
	else:
		logging.info( "TopoSCALE already run: " + os.path.basename(os.path.normpath(Ngrid)) )
	#====================================================================
	#	setup and run simulations
	#====================================================================
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





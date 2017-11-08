#!/usr/bin/env python
import os
import os.path
import logging
import subprocess

def main( config , shp):

	# set up directory
	sca_wd=config["main"]["wd"] + "/MODIS/SC"
	if not os.path.exists(sca_wd):
		os.makedirs(sca_wd)

	cmd = ["./DA/updateOptions.sh" , config["main"]["startDate"] , config["main"]["endDate"] , config["modis"]["options_file_SCA"], sca_wd]
	subprocess.check_output( cmd)

	# run MODIStsp tool	
	from DA import getMODIS as gmod
	gmod.main("FALSE" , config["modis"]["options_file_SCA"], shp ) #  able to run non-interactively now

# calling main
if __name__ == '__main__':
	import sys
	config      = sys.argv[1]
	shp      = sys.argv[2]
	main( config, shp)
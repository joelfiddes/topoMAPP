#!/usr/bin/env python
import sys
import os
import subprocess
import logging
import os.path
from listpoints_make import getRasterDims as dims
import glob


#====================================================================
#	TOPOSUB: Toposub.R contains hardcoded "normal" parameters 
#====================================================================
from utils import fileSearch
path=wd
file="landform.tif"
x=fileSearch.search(path, file)
if x != 1: #NOT ROBUST

	print "[INFO]: running TopoSUB for grid " + str(Ngrid)

	from toposub import toposub as tsub
	tsub.main(gridpath, config["toposub"]["samples"])	

else:
	print "[INFO]: TopoSUB already run"


#====================================================================
#	run toposcale
#====================================================================
print "[INFO]: Running TopoSCALE"
import TMtoposcale

#====================================================================
#	setup and run simulations
#====================================================================
import TMsim.py

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
	import TMtoposcale
	


#====================================================================
#	Setup Geotop simulations INFORM!!
#====================================================================

	#ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
	print "[INFO]: Setup Geotop simulations INFORM!" 
	import TMsim.py


#====================================================================
#	Spatialise toposub results SIMULATION MEAN
#====================================================================

print "[INFO]: Spatialising TopoSUB results...."

for Ngrid in grid_dirs:	
	gridpath = str(Ngrid)
	print "[INFO]: running spatialisation routines for grid " + str(Ngrid)
	from toposub import toposub_post2 as post2
	post2.main(gridpath, config["toposub"]["samples"],config["geotop"]["file1"],config["geotop"]["targV"],config["main"]["startDate"],config["main"]["endDate"] )	


#====================================================================
#	Spatialise toposub results LATEST
#====================================================================

print "[INFO]: Spatialising TopoSUB results...."

for Ngrid in grid_dirs:	
	gridpath = str(Ngrid)

	print "[INFO]: running spatialisation routines for grid " + str(Ngrid)
	from toposub import toposub_postInstant as postInst
	postInst.main(gridpath, config["toposub"]["samples"],config["geotop"]["file1"],config["geotop"]["targV"] )	

#====================================================================
#	Averaged coarse grid timeseries of toposub results 
#====================================================================


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

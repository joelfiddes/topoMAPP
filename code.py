#!/usr/bin/env python
# import ipdb
# ipdb.set_trace

""" This is a port of run_points.sh"""
import sys
import os
import subprocess
import logging
#============= LOGGING =========================================

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# logger.info("Start reading database")
# # read database here
# records = {"john": 55, "tom": 66}
# logger.debug("Records: %s", records)
# logger.info("Updating records ...")
# # update records here
# logger.info("Finish updating records")
#================================================================


sys.path.append("/home/joel/src/TOPOMAP/toposubv2/topoMAPP/")
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
#	Config file
#====================================================================
from configobj import ConfigObj
config = ConfigObj("topomapp.conf")
wd = config["main"]["wd"]

#====================================================================
#	Setup domain
#====================================================================
from domain_setup import getDEM_points as gdem
gdem.main(wd ,config["main"]["demDir"] ,config["era-interim"]["grid"], config["main"]["pointsFile"], config["main"]["lonCol"], config["main"]["latCol"])

from domain_setup import clipToEra as era
era.main(wd ,config["era-interim"]["grid"])

from domain_setup import makeShape as shp
shp.main(wd , config["main"]["pointsFile"], config["main"]["lonCol"], config["main"]["latCol"])
          
from domain_setup import domainPlot as dplot
dplot.main(wd , "TRUE") # shp = TRUE for points  run

from domain_setup import makeKML as kml
kml.main(wd, wd + "/predictors/ele.tif", "shape", wd + "/spatial/extent")
        
kml.main(wd, wd + "/spatial/eraExtent.tif", "raster", wd + "/spatial/eraExtent")

from domain_setup import computeTopo as topo
topo.main(wd, config["toposcale"]["svfCompute"])

from domain_setup import makeSurface as surf
surf.main(wd, config["modis"]["MODISdir"] )

#====================================================================
#	GET ERA
#====================================================================
from getERA import getExtent as ext
latN = ext.main(wd + "/predictors/ele.tif" , "latN")
latS = ext.main(wd + "/predictors/ele.tif" , "latS")
lonW = ext.main(wd + "/predictors/ele.tif" , "lonW")
lonE = ext.main(wd + "/predictors/ele.tif" , "lonE")

eraDir = wd + "/eraDat"
if not os.path.exists(eraDir):
	os.mkdir(eraDir)


from getERA import eraRetrievePLEVEL as plevel
print "Retrieving ECWMF pressure-level data"
plevel.retrieve_interim( config["main"]["startDate"], config["main"]["endDate"], latN, latS, lonE, lonW, config["era-interim"]["grid"],eraDir)

from getERA import eraRetrieveSURFACE as surf
print "Retrieving ECWMF surface data"
surf.retrieve_interim(config["main"]["startDate"], config["main"]["endDate"], latN, latS, lonE, lonW, config["era-interim"]["grid"],eraDir)

# Merge NDF timeseries (requires linux package cdo)
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

print("Running:" + str(cmd))
subprocess.check_output(cmd, shell = "TRUE")

#os.chdir(config["main"]["srcdir"])

from getERA import era_prep as prep
prep.main(wd, config["main"]["startDate"], config["main"]["endDate"])

from getERA import prepSims as sim
sim.main(wd)

#====================================================================
#	makeListpoint: creates a listpoints for each ERA-grid, only 
#	required for point runs
#====================================================================
# 

from listpoints_make import getRasterDims as dims
ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")

print "Setting up simulation directories for " + ncells  + " ERA-Grids" 

# set up sim directoroes #and write metfiles
for Ngrid in range(1,int(ncells)):
	gridpath=wd +"/grid"+ str(Ngrid)
	print "creating listpoints for grid " + str(Ngrid)
	from listpoints_make import makeListpoints as list
	list.main(gridpath, config["main"]["pointsFile"],config["main"]["pkCol"], config["main"]["lonCol"], config["main"]["latCol"])

#====================================================================
#	run toposcale
#====================================================================

ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
print "Running TopoSCALE"

from toposcale import getGridEle as gele
gele.main(wd)

# set up sim directoroes #and write metfiles
for Ngrid in range(1,int(ncells)):
	gridpath = wd +"/grid"+ str(Ngrid)

	if os.path.exists(gridpath):
		print "running toposcale for grid " + str(Ngrid)

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
		print "Grid "+ str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid+1)

#====================================================================
#	Setup Geotop simulations
#====================================================================

ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
print "Setup Geotop simulations" 

# set up sim directoroes #and write metfiles
for Ngrid in range(1,int(ncells)):
	gridpath = wd +"/grid"+ str(Ngrid)

	if os.path.exists(gridpath):
		print "Setting up geotop inputs " + str(Ngrid)

	 	print "Creating met files...."
	 	from gtop_setup import prepMet as met
		met.main(gridpath, config["toposcale"]["svfCompute"])

		print "extract surface properties"
		from gtop_setup import pointsSurface as psurf
		psurf.main(gridpath)

		print "making inputs file"
		from gtop_setup import makeGeotopInputs as gInput
		gInput.main(gridpath, config["geotop"]["geotopInputsPath"], config["main"]["startDate"], config["main"]["endDate"])

	else:
		print "Grid "+ str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid+1)


#====================================================================
#	Run LSM
#====================================================================
ncells = dims.main(wd, wd + "/spatial/eraExtent.tif")
print "Running LSM" 

# set up sim directoroes #and write metfiles
for Ngrid in range(1,int(ncells)):
	gridpath = wd +"/grid"+ str(Ngrid)

	if os.path.exists(gridpath):

	 	print "Simulations grid" + str(Ngrid) + " running"
		batchfile="batch.sh"

		sim_entries=gridpath +"/S*"

		f = open(batchfile, "w+")
		f.write("#!/bin/bash"+ '\n')
		f.write("cd " + config["geotop"]["lsmPath"] + '\n')
		f.write("parallel " + "./" + config["geotop"]["lsmExe"] + " ::: " + sim_entries + '\n')
		f.close()

		import os, sys, stat
		os.chmod(batchfile, stat.S_IRWXU)

		cmd     = ["./" + batchfile]
		subprocess.check_output( "./" + batchfile )

	else:
		print "Grid "+ str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid+1)

#====================================================================
#	Get MODIS SCA
#====================================================================

# clear data
import os, shutil
folder = config['modis']['sca_wd']
for the_file in os.listdir(folder):
    file_path = os.path.join(folder, the_file)
    try:
        if os.path.isfile(file_path):
            os.unlink(file_path)
        elif os.path.isdir(file_path): shutil.rmtree(file_path)
    except Exception as e:
        print(e)

# compute from dem
from getERA import getExtent as ext
latN = ext.main(wd + "/predictors/ele.tif" , "latN")
latS = ext.main(wd + "/predictors/ele.tif" , "latS")
lonW = ext.main(wd + "/predictors/ele.tif" , "lonW")
lonE = ext.main(wd + "/predictors/ele.tif" , "lonE")

# call bash script that does grep type stuff to update values in options file
cmd = ["./DA/updateOptions.sh" , lonW , latS , lonE , latN , config['main']['startDate'] , config['main']['endDate'] , config['modis']['options_file']]
subprocess.check_output( cmd)

# run MODIStsp tool\
from DA import getMODIS as gmod
gmod.main('FALSE' , config['modis']['options_file']) #  able to run non-interactively now

# extract timersies per point
from DA import scaTS
scaTS.main(wd ,config['modis']['sca_wd'] + "/Snow_Cov_Daily_500m_v5/SC" ,wd + "/spatial/points.shp" )

# POSTPROCESS FSCA FILES TO FILL GAPS (linearly interpolate)
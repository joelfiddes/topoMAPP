#!/usr/bin/env python

""" https://configobj.readthedocs.io/en/latest/configobj.html#introduction

The config files that ConfigObj will read and write are based on the "INI" format. This means it will read and write files created for ConfigParser.
	
	Keywords and values are separated by an, and section markers are between square brackets. Keywords, values, and section names can be surrounded by single or double quotes. Indentation is not significant, but can be preserved.
	
	Subsections are indicated by repeating the square brackets in the section marker. You nest levels by using more brackets.
	You can have list values by separating items with a comma, and values spanning multiple lines by using triple quotes (single or double). """

from configobj import ConfigObj
config = ConfigObj()
config.filename = "ini/test_code.ini"


#=================================================================
# paths to set
#=================================================================
simroot = "/home/joel/sim"
srcroot = "/home/joel/src"
datroot = "/home/joel/data"

#=================================================================
# Main
#=================================================================
config["main"] = {}
config["main"]["wd"] = simroot +"/test_code" # main work directory
config["main"]["srcdir"] = srcroot +"/topoMAPP" # src code dir
config["main"]["demDir"] = datroot +"/DEM/srtm" # dem write dir
config["main"]["runtype"] = "bbox" #one of : bbox, points
config["main"]["mode"] =# one of: NORM, ENSEMB,  DA, 
config["main"]["startDate"] = "2015-09-01"
config["main"]["endDate"] = "2015-09-02"
config["main"]["shp"] = datroot +"/GCOS/wfj_poly.shp"
config["main"]["tz"] = -1

# control quick starts
config["main"]["initSim"] = "FALSE" # initialises interim data and dem from existing to allow perturbed experiment 
config["main"]["initDir"] = simroot +"/da_test"
config["main"]["initGrid"] = 1 # can be single number or comma seperated list eg. 1,2,3

# option to supply own dem - doesnt work yet
config["main"]["demexists"] = "FALSE"
config["main"]["dempath"] = "/home/joel/Downloads/20170904031934_280341969.tif"
config["main"]["spatialResults"] = "FALSE"

#=================================================================
# ERA-Interim
#=================================================================
config["era-interim"] = {}
config["era-interim"]["grid"] = 0.3 #0.75, 0.3
config["era-interim"]["dataset"] = "era5" #"era5" "interim"
config["era-interim"]["domain"] = srcroot +"/topoMAPP/dat/era5grid30.tif" # "/home/joel/src/topoMAPP/dat/eraigrid75.tif" 

#=================================================================
# TopoSUb
#=================================================================
config["toposub"] = {}
config["toposub"]["samples"] = 10
config["toposub"]["inform"] = "TRUE"

#=================================================================
# TopoSCale
#=================================================================
config["toposcale"] = {}
config["toposcale"]["tscaleOnly"] = "FALSE"
config["toposcale"]["swTopo"] = "FALSE"
config["toposcale"]["svfCompute"] = "TRUE"
config["toposcale"]["pfactor"] = 0.25

#=================================================================
# GEOTOP
#=================================================================
config["geotop"] = {}
config["geotop"]["file1"] = "surface.txt" #"ground.txt" #"
config["geotop"]["targV"] = "snow_water_equivalent.mm." # "X100.000000" # 
config["geotop"]["num_cores"] =2

#=================================================================
# MODIS
#=================================================================
config["modis"] = {}
config["modis"]["getMODISSCA"] = "TRUE"
#config["modis"]["startDateSCA"]="2010-09-01" # same as startDate 
#config["modis"]["endDateSCA"] = "2015-09-01" # same as endDate

#=================================================================
# ENSEMBLE
#=================================================================
config["ensemble"] = {}
config["ensemble"]["run"] = "FALSE"
config["ensemble"]["members"] = 100

#=================================================================
#
# Dont normally touch
#
#=================================================================

#=================================================================
# GEOTOP
#=================================================================
config["geotop"]["geotopInputsPath"] = srcroot +"/topoMAPP/geotop/geotop.inpts"
config["geotop"]["lsmPath"] = srcroot +"/topoMAPP/geotop/"
config["geotop"]["lsmExe"] = "geotop1.226"

#=================================================================
# MODIS
#=================================================================
# location of MODIStsp options file
config["modis"]["options_file_SCA"] = srcroot +"/topoMAPP/DA/optionsSCA.json"
config["modis"]["options_file_NDVI"] = srcroot +"/topoMAPP/DA/optionsNDVI.json"

#=================================================================
# DA
#=================================================================
config["da"] = {}
config["da"]["pscale"] = 1 #factor to multiply precip by
config["da"]["tscale"] = 0 #factor to add to temp
config["da"]["lwscale"] = 0 #factor to add to temp
config["da"]["swscale"] = 0 #factor to add to temp

config.write()





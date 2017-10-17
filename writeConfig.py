#!/usr/bin/env python

''' https://configobj.readthedocs.io/en/latest/configobj.html#introduction

The config files that ConfigObj will read and write are based on the 'INI' format. This means it will read and write files created for ConfigParser.
	
	Keywords and values are separated by an, and section markers are between square brackets. Keywords, values, and section names can be surrounded by single or double quotes. Indentation is not significant, but can be preserved.
	
	Subsections are indicated by repeating the square brackets in the section marker. You nest levels by using more brackets.
	You can have list values by separating items with a comma, and values spanning multiple lines by using triple quotes (single or double). '''

from configobj import ConfigObj
config = ConfigObj()
config.filename = 'test.ini'


#=================================================================
# GENERALLY CHANGE
#=================================================================


#=================================================================
# Main
#=================================================================
config['main'] = {}
config['main']['wd'] = '/home/joel/sim/test_era5/'
config['main']['srcdir'] = '/home/joel/src/topoMAPP'
config['main']['demDir'] = '/home/joel/data/DEM/srtm'
config['main']['runtype'] = 'bbox' #bbox or points add toposcale only option here
config['main']['startDate'] = '2015-09-01'
config['main']['endDate'] = '2015-09-03'

#config['main']['lonw'] = 8
#config['main']['lats'] = 46
#config['main']['lone'] = 9
#config['main']['latn'] = 47

#config['main']['pointsFile'] = '/home/joel/data/GCOS/pointsTEST.txt' # only for points
#config['main']['pkCol'] = 1
#config['main']['lonCol'] = 2
#config['main']['latCol'] = 3
config['main']['shp'] = "/home/joel/data/GCOS/wfj_poly.shp"
config['main']['tz'] = -1
#config['main']['googleEarthPlots'] = 'FALSE'
#config['main']['informSample'] = 'FALSE'

# control quick starts
config['main']['initSim'] = 'FALSE' # initialises interim data and dem from existing to allow perturbed experiment 
config['main']['initDir'] = '/home/joel/sim/da_test'
config['main']['initGrid'] = 1 # optional subset of grids to init sim with, can be "*" for all grids

# option to supply own dem - doesnt work yet
config['main']['demexists'] = 'FALSE'
config['main']['dempath'] = '/home/joel/Downloads/20170904031934_280341969.tif'
#=================================================================
# ERA-Interim
#=================================================================
config['era-interim'] = {}

# These configs are not independent
config['era-interim']['grid'] = 0.3 #0.75, 0.3
config['era-interim']['dataset'] = "era5" #"era5" "interim"
config['era-interim']['domain'] = "/home/joel/src/topoMAPP/dat/era5grid30.tif" #"/home/joel/src/topoMAPP/dat/eraigrid75.tif"

# https://software.ecmwf.int/wiki/display/CKB/Does+downloading+data+at+higher+resolution+improve+the+output
#=================================================================
# TopoSUb
#=================================================================
config['toposub'] = {}
config['toposub']['samples'] = 10
config['toposub']['inform'] = 'TRUE'

#=================================================================
# TopoSCale
#=================================================================
config['toposcale'] = {}
config['toposcale']['swTopo'] = 'FALSE'
config['toposcale']['svfCompute'] = 'FALSE'
config['toposcale']['pfactor'] = 0.25

#=================================================================
# GEOTOP
#=================================================================
config['geotop'] = {}

# Define target variable  (make a list possible here)
config['geotop']['file1'] = 'ground.txt' #'ground.txt' #'
config['geotop']['targV'] = 'X100.000000' #'snow_water_equivalent.mm.' # 'X100.000000' # 
#config['geotop']['beg'] = "01/09/2015 00:00:00" # fix this to accept main time parameters
#config['geotop']['end'] =	"01/09/2016 00:00:00" # fix this to accept main time parameters


#=================================================================
# MODIS
#=================================================================
config['modis'] = {}

#config['modis']['sca_wd'] = '/home/joel/data/MODIS_ARC/SCA/data'
#config['modis']['MODISdir'] = '/home/joel/data/MODIS_ARC/PROCESSED' # NDVI
config['modis']['getMODISSCA'] = "TRUE"
config['modis']['tileX_start'] = 18 # this is interim measure used as bbox doesnt work if outside specified tile
config['modis']['tileX_end'] = 18# this is interim measure used as bbox doesnt work if outside specified tile
config['modis']['tileY_start'] = 4
config['modis']['tileY_end'] = 4



#=================================================================
#
# Dont normally touch
#
#=================================================================

#=================================================================
# GEOTOP
#=================================================================
config['geotop']['geotopInputsPath'] = '/home/joel/src/geotop/inputsfile/geotop.inpts'
config['geotop']['lsmPath'] = '/home/joel/src/geotop/geotop1.226'
config['geotop']['lsmExe'] = 'geotop1.226'
#=================================================================
# MODIS
#=================================================================
# location of MODIStsp options file
config['modis']['options_file_SCA'] = '/home/joel/src/topoMAPP/DA/optionsSCA.json'
config['modis']['options_file_NDVI'] = '/home/joel/src/topoMAPP/DA/optionsNDVI.json'
#=================================================================
# DA
#=================================================================
config['da'] = {}
config['da']['pscale'] = 1 #factor to multiply precip by
config['da']['tscale'] = 0 #factor to add to temp

config.write()

# dynamically plot KML on the fly
# #https://github.com/lbusett/MODIStsp
# requires existing parameter file at options_file set up by running 
# require(MODIStsp) 
# MODIStsp()
# startdate enddate and AOI updated by TOPOSAT

#MODES
# - point sim (toposcale + 1D model) POINT
# - large area spatial sim (toposcale + toposub + 1D model) BBOX
# - basin sim (full 2d eg run off etc) (toposcale + 2D model) BASIN

# make kml and plot on googleearth



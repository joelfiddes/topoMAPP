#!/usr/bin/env python

''' https://configobj.readthedocs.io/en/latest/configobj.html#introduction

The config files that ConfigObj will read and write are based on the 'INI' format. This means it will read and write files created for ConfigParser.
	
	Keywords and values are separated by an, and section markers are between square brackets. Keywords, values, and section names can be surrounded by single or double quotes. Indentation is not significant, but can be preserved.
	
	Subsections are indicated by repeating the square brackets in the section marker. You nest levels by using more brackets.
	You can have list values by separating items with a comma, and values spanning multiple lines by using triple quotes (single or double). '''

from configobj import ConfigObj
config = ConfigObj()
config.filename = 'topomapp.conf'

#=================================================================
# Main
#=================================================================
config['main'] = {}
config['main']['wd'] = '/home/joel/sim/topomap_augtest/'
config['main']['srcdir'] = '/home/joel/src/TOPOMAP/toposubv2/topoMAPP'
config['main']['demDir'] = '/home/joel/data/DEM/srtm'
config['main']['runtype'] = 'bbox' #bbox or points add toposcale only option here
config['main']['startDate'] = '2011-09-01'
config['main']['endDate'] = '2011-12-05'

config['main']['lonw'] = 9.7
config['main']['lats'] = 46.7
config['main']['lone'] = 9.9
config['main']['latn'] = 46.9

config['main']['pointsFile'] = '/home/joel/data/GCOS/points_all.txt' # only for points
config['main']['pkCol'] = 1
config['main']['lonCol'] = 2
config['main']['latCol'] = 3
config['main']['tz'] = -1
config['main']['googleEarthPlots'] = 'TRUE'
config['main']['informSample'] = 'FALSE'

#=================================================================
# ERA-Interim
#=================================================================
config['era-interim'] = {}
config['era-interim']['grid'] = 0.75

#=================================================================
# TopoSUb
#=================================================================
config['toposub'] = {}
config['toposub']['samples'] = 50
 

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
config['geotop']['geotopInputsPath'] = '/home/joel/src/geotop/inputsfile/geotop.inpts'
config['geotop']['lsmPath'] = '/home/joel/src/geotop/geotop1.226'
config['geotop']['lsmExe'] = 'geotop1.226'
config['geotop']['file1'] = 'surface.txt'
config['geotop']['targV'] = 'snow_water_equivalent.mm.'#'X100.000000' # 'snow_water_equivalent.mm.'
config['geotop']['beg'] = "02/09/2011 00:00:00" # fix this to accept main time parameters
config['geotop']['end'] =	"04/12/2012 00:00:00" # fix this to accept main time parameters

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

#=================================================================
# Validation
#================================================================
config['validation'] = {}
config['validation']['valDat'] = '/home/joel/valData2009.txt'
config['validation']['modDat'] = 'meanX_X100.000000.txt'
config['validation']['magstCol'] = 3
config['validation']['lonCol'] = 7
config['validation']['latCol'] = 8

#=================================================================
# MODIS
#=================================================================
config['modis'] = {}
config['modis']['options_file'] = '/home/joel/data/MODIS_ARC/SCA/options.json'
config['modis']['sca_wd'] = '/home/joel/data/MODIS_ARC/SCA/data'
config['modis']['MODISdir'] = '/home/joel/data/MODIS_ARC/PROCESSED' # NDVI
# location of MODIStsp options file

#=================================================================
# DA
#=================================================================
config['da'] = {}
config['da']['precipScale'] = 1 #factor to multiply precip by
config['da']['tempScale'] = 0 #factor to add to temp
config.write()




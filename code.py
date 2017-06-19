#!/usr/bin/env python

import sys
import os
sys.path.append('/home/joel/src/TOPOMAP/toposubv2/topoMAPP/')
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

#config
from configobj import ConfigObj
config = ConfigObj('topomapp.conf')
wd = config['main']['wd']

# SETUP DOMAIN
from domain_setup import getDEM_points as gdem
gdem.main(wd ,config['main']['demDir'] ,config['era-interim']['grid'], config['main']['pointsFile'], config['main']['lonCol'], config['main']['latCol'])

from domain_setup import clipToEra as era
era.main(wd ,config['era-interim']['grid'])

from domain_setup import makeShape as shp
shp.main(wd , config['main']['pointsFile'], config['main']['lonCol'], config['main']['latCol'])
          
from domain_setup import domainPlot as dplot
dplot.main(wd , "TRUE") # shp = TRUE for points  run

from domain_setup import makeKML as kml
kml.main(wd, wd + '/predictors/ele.tif', "shape", wd + '/spatial/extent')
        
kml.main(wd, wd + '/spatial/eraExtent.tif', "raster", wd + '/spatial/eraExtent')

from domain_setup import computeTopo as topo
topo.main(wd, config['toposcale']['svfCompute'])

from domain_setup import makeSurface as surf
surf.main(wd, config['modis']['MODISdir'] )

# GET ERA
from getERA import getExtent as ext
latN = ext.main(wd + '/predictors/ele.tif' , "latN")
latS = ext.main(wd + '/predictors/ele.tif' , "latS")
lonW = ext.main(wd + '/predictors/ele.tif' , "lonW")
lonE = ext.main(wd + '/predictors/ele.tif' , "lonE")

eraDir = wd + '/eraDat'
os.mkdir(eraDir)


from getERA import eraRetrievePLEVEL as plevel
print "Retrieving ECWMF pressure-level data"
plevel.retrieve_interim( config['main']['startDate'], config['main']['endDate'], latN, latS, lonE, lonW, config['era-interim']['grid'],eraDir)

from getERA import eraRetrieveSURFACE as surf
print "Retrieving ECWMF surface data"
surf.retrieve_interim(config['main']['startDate'], config['main']['endDate'], latN, latS, lonE, lonW, config['era-interim']['grid'],eraDir)
#!/bin/bash
echo $(basename $BASH_SOURCE)  'running........'
source $wd/toposat.ini
mkdir $wd/spatial

# Fetch DEM(s) for bbox
Rscript getDEM.R $wd $demDir $positions 

# Clip to nearest ERA-extent
Rscript clipToEra.R $wd $grid

#domain plot
Rscript domainPlot.R $wd TRUE

# generate kml of domain

Rscript makeKML.R $wd $wd/predictors/ele.tif shape $wd/spatial/extent
Rscript makeKML.R $wd $wd/spatial/eraExtent.tif raster $wd/spatial/eraExtent
pkill googleearth-bin 
 # kill any existing GE processes
google-earth $wd/spatial/eraExtent.kmz &

# Generate topo layers
Rscript computeTopo.R $wd $svfCompute

#clean up old processed MODIS files
cd $MODISdir
cd ../
rm -r PROCESSED
mkdir PROCESSED
cd $srcdir

# Make surface from MODIS (fetch) and DEM
Rscript makeSurface.R $wd $MODISdir

# generate kml of landcover
Rscript makeKML.R $wd $wd/predictors/surface.tif raster $wd/spatial/landcover
pkill googleearth-bin 

google-earth $wd/spatial/landcover.kmz &
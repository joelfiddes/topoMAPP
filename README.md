
# Introduction: TopoMAPP

*Project in active development - not ready for running out the box, provided as is with no guarantee of stability.*

This modelling framework combines previously published tools TopoSUB and TopoSCALE with ensemble and data assimilation methods. The tool can be run in 3 modes:
- NORM
- ENSEMBLE
- DA

and at 2 spatial geometries:
- AOI / bbox
- point

Key functions:
- Automated handling of all download requirements
- Downscaling routines
- Efficient numerical simulartor
- Ensemble simulations
- Data assimilation routines

# Setup
## To run
1. set config by:
- edit writeConfig.py
- python writeConfig.py (generates INI file)
2. ./run_topomap.sh fullpath2INI
## Logging
- meaningful messages (set by logging module) in workdir "logfile"
- stdout redirected to file stdout.log in ./topomapp src code directory

## Dependencies
- Detailed in dependencies.txt
- Linux 16.04 (probably works on 14.04 too)
- GDAL > v.2 
- CDO
- Rlibs (tobe detailed/packaged)
- Pythonlibs (tobe detailed/ packaged)
- Geotop model (binary included / packaged) http://geotopmodel.github.io/geotop/

## Structure
Main code-base is R code,  Python is used as a wrapper and to give the project architecture. Plus a dash of bash.

## Data download
MODIS and SRTM data are required by TopoMAPP and download is handled by separate tools but one NASA accounts here:
https://urs.earthdata.nasa.gov/profile

### MODIS
MODIS download is handled by the really great R package MODIStsp available on CRAN and here: https://github.com/lbusett/MODIStsp

MODIS data is required to define the surface based on NDVI (Vegetation Indexes_16Days_250m (M*D13Q1)) and optionally in the DA routines where MODIS snow products are retrieved (Snow_Cov_Daily_500m (M*D10_A1)). Options file for configuring the download is described below

### SRTM
Account required https://urs.earthdata.nasa.gov/profile and credentials file here:
``` ~/.netrc```
Download is implemented using wget from this server:
http://e4ftl01.cr.usgs.gov//MODV6_Dal_D/SRTM/SRTMGL1.003/2000.02.11/

and downloads closest 1x1 degree tiles to AOI using a snap out algorithm (AOI is completely enclosed by downloaded domain). It is quite simple but does some smart things like check if the requested data already exists in the ```config['main']['demDir']```.

## Config  
There are three types of config
- main INI: this controls the modelling scheme and is edited every time a run is setup.
- Geotop INPTS: model parameters and all thing GeoTOP are defined here. This does not need to be edited regularly. Set and forget.
- MODIS JSON: these 2 configuration files setup the MODIS download of NDVI and SCA. They usually don't need to be edited manually except on firt use where credentials from earthdata account need to be entered.


# What it does

## Modes

## Config variables

## Setting up domain
- The domain is defined by a shape file either of polygon or points geometry. Based on this TopoMAPP retrieves SRTM DEM required for AOI.
- 

## ECWMF reanalysis
This is costly to download especially higher resolution ERA5 (approx. 1.5h /year/ 20 grids / 80mbps line). Howver this is all fully automated so you can set and forget and leave to run on your server overnight or however long is required. Once downloaded you can run muultiple experiments (eg. ensemble simulations) without requiring further download as long as your temporal and spatial domain do not change.

- The code uses joblib to parallelise the requests according to num_core variable. 
- 3 active and 20 queued requests are permitted by the api: https://software.ecmwf.int/wiki/display/WEBAPI/WebAPI+FAQ#WebAPIFAQ-Isthereanylimitationonthenumberofrequeststhatausercansubmit?
- If there are failures simply rerun and will check what is already downloaded and what still required. 
- ECWMF joblist portal can be useful for checking progress, jobs submitted etc: http://apps.ecmwf.int/webmars/joblist/

## TopoSUB

## TopoSCALE

## Probabilistic

## Data assimilation

##

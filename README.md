
# Introduction: TopoMAPP

** WORK IN PROGRESS - not ready for running out the box, get in touch if would like to know more help in setting this up **
This modelling framework combines previously published tools TopoSUB and TopoSCALE with ensemble and data assimilation methods. The tool can be run in 3 modes:
- NORM
- ENSEMBLE
- DA

and at 2 spatial geometries:
- AOI / bbox
- point

# Setup
## To run
1. set config by:
- edit writeConfig.py
- python writeConfig.py
2. ./run_topomap.sh fullpathToInifile

## Logging
- meaningful messages (set by logging module) in workdir "logfile"
- stdout redirected to file stdout.log in ./topomapp src code directory

## Dependencies
- Linux 16.04 (probably works on 14.04 too)
- GDAL > v.2 
- CDO
- Rlibs (tobe detailed/packaged)
- Pythonlibs (tobe detailed/ packaged)
- Geotop model (binary included / packaged) http://geotopmodel.github.io/geotop/

## Structure
Main code-base is R code,  Python is used as a wrapper and to give the project architecture. Plus a dash of bash.

## Config  
There are three types of config
- main INI: this controls the modelling scheme and is edited every time a run is setup.
- Geotop INPTS: model parameters and all thing GeoTOP are defined here. This does not need to be edited regularly. Set and forget.
- MODIS JSON: these 2 configuration files setup the MODIS download of NDVI and SCA. They usually don't need to be edited manually

# What it does

## Modes

## Config

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

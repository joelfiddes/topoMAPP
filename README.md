
# TopoMAPP

This modelling framework combines previously published tools TopoSUB and TopoSCALE with ensemble and data assimilation methods. The tool can be run in 3 modes:
- NORM
- ENSEMBLE
- DA

and at 2 scales:
- bbox
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
- GDAL > 2 MODIS R package
- CDO
- Rlibs (packaged)
- Pythonlibs (packaged)
- Geotop (packaged)

## Structure
Main code-base is R code,  Python is used as a wrapper and to give the project some architecture. Plus a dash of bash.

## Config  
There are three types of config
- main INI: this controls the modelling scheme and is edited every time a run is setup.
- Geotop INPTS: model parameters and all thing GeoTOP are defined here. This does not need to be edited regularly. Set and forget.
- MODIS JSON: these 2 configuration files setup the MODIS download of NDVI and SCA. They usually don't need to be edited manually


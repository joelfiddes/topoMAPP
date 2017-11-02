
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

2. create wd manually
3. ./run_topomap.sh fullpathToInifile

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
Describe python/ R setup here

## Config  

## Todo
- check files exist and skip module if so

## Notes
- lon and lat written to lsp in toposub.R as mean values of grid - this is required by toposcale_sw in FALSE mode
- makeSurface.R requires massive matrix calc (10+GB) and crashes frequently SOLVED
- need to reconcile shifts in domain when clip to ERA-grids
- automate optional cleaning (command libne arg 'clean') and config run at start 

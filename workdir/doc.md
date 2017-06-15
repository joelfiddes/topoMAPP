Package: toposubv2

# MODE: run_points.sh

In this mode a set of points are defined (long,lat) by a csv file. Unit of simulation is  point. The method does the following steps:

1. Download DEM covering points
2. Compute topographic parameters
3. Compute surface characteristics (MODIS NDVI + topo)
4. Download ERA data corresponding to point location (nearest neighbour, interpolation next job)
5. Run LSM
6. Download SCA for points
7. Extract FSC timeseries
8. Data assimilation
9. Validation

## setupDomain_points.sh
### Modules
- getDEM_points.R
- clipToEra.R
- makeKML.R
- computeTopo.R
- makeSurface.R

### In
- toposat.ini

### Out
- dem.tif
- ele.tif (clipped dem.tif to ERA extent as defined by ERA grids that correspond to domain. These are the ERA- grids enclosed in the dem )
- slp/asp/svf
- surface

## getERA2.sh
### Modules
- eraRetrievePLEVEL.py
- eraRetrieveSURFACE.py
- toposcale_pre2.R
- prepareSims.R

### In
### Out
- preprocessed ERA data timeseries
- 

## makeListpoints.sh
1. creates listpoints file at grid level\
2. removes ERA-grids with no points
### Modules
makeListpoints.R
### In
### Out


## runTopoSCALE.sh
### Modules
### In
### Out

##setupGeotopSim.sh
### Modules
### In
### Out

##runLSM.sh
### Modules
### In
### Out

##validate.sh
### Modules
### In
### Out

##spatialise.sh
### Modules
### In
### Out

##getMODIS_SCA.sh
### Modules
### In
### Out

# MODE: run_bbox.sh
In this mode and aoi is specified though a bbox (4 coords). Unit of simulation is a toposub sample within ERA-grid
##setupDomain.sh
### Modules
### In
### Out

##getERA.sh
### Modules
### In
### Out

##runTopoSUB.sh
### Modules
### In
### Out

##runTopoSCALE.sh
### Modules
### In
### Out

##setupGeotopSim.sh
### Modules
### In
### Out

##runLSM.sh
### Modules
### In
### Out

##informSample.sh
### Modules
### In
### Out

##validate.sh
### Modules
### In
### Out

##spatialise.sh
### Modules
### In
### Out

##getMODIS_SCA.sh 
### Modules
### In
### Out



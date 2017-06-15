#!/bin/bash
echo $(basename $BASH_SOURCE)  'running........'
wd=$1
echo $wd
source $wd/toposat.ini

# restructured to ensure one request per reel - order of magnitudes quicker.

# compute from dem
latNorth=$(Rscript getExtent.R $wd/predictors/ele.tif latN)
latSouth=$(Rscript getExtent.R $wd/predictors/ele.tif latS)
lonEast=$(Rscript getExtent.R $wd/predictors/ele.tif lonE)
lonWest=$(Rscript getExtent.R $wd/predictors/ele.tif lonW)
eraDir=$wd/eraDat
mkdir $eraDir

echo "Retrieving ECWMF pressure-level data"
python eraRetrievePLEVEL.py $startDate $endDate $latNorth $latSouth $lonEast $lonWest $grid $eraDir
echo "Retrieving ECWMF surface data"
python eraRetrieveSURFACE.py $startDate $endDate $latNorth $latSouth $lonEast $lonWest $grid $eraDir

# Merge NDF timeseries (requires linux package cdo)
cd $eraDir
cdo -b F64 -f nc2 mergetime interim_daily_PLEVEL* PLEVEL.nc
cdo -b F64 -f nc2 mergetime interim_daily_SURF* SURF.nc
cd $srcdir

# Preprocess ERA-data
Rscript toposcale_pre2.R $wd $startDate $endDate

# Prepare sim predicters and directories per ERA-grid
Rscript prepareSims.R $wd
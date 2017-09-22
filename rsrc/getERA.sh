#!/bin/bash
echo $(basename $BASH_SOURCE)  'running........'
source $wd/toposat.ini

# Fetch ERA-data
Rscript getERA.R $wd $runtype $startDate $endDate $grid

# Preprocess ERA-data
Rscript toposcale_pre.R $wd $startDate $endDate

# Prepare sim predicters and directories per ERA-grid
Rscript prepareSims.R $wd
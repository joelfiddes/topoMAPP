#!/bin/bash
# these will all be fed from config
sca_wd # contains all the modis data
wd # ensemble
priorwd # NORM
grid = # grid number
nens = 50

echo "run PBS"
Rscript rsrc/PBSpixel_test.R 180 350 0


Rscript 

echo "calc SWE"
Rscript rsrc/PBSpix2samp_test.R 

echo "calc SCA"
Rscript rsrc/daSCAplot.R 

Rscript rsrc/daSCAplot_grid.R 

#make grid level plot

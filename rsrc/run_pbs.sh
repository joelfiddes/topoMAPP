#!/bin/bash

echo "run PBS"
Rscript rsrc/PBSpixel_test.R 180 350 13

echo "calc SWE"
Rscript rsrc/PBSpix2samp_test.R 

echo "calc SCA"
Rscript rsrc/daSCAplot.R 

#make grid level plot

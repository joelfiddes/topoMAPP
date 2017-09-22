#!/bin/bash
echo $(basename $BASH_SOURCE)  'running........'
source $wd/toposat.ini

Rscript plotExtents.R $wd

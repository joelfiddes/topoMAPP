#!/bin/bash
cd /home/joel/src/geotop/geotop1.226
parallel ./geotop1.226 ::: /home/joel/sim/da_test2/grid1/S*

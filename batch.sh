#!/bin/bash
cd /home/joel/src/geotop/geotop1.226
parallel ./geotop1.226 ::: /home/joel/sim/ensembler_testRadflux/ensemble0/grid2/S*

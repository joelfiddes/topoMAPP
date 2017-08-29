#!/bin/bash
cd /home/joel/src/geotop/geotop1.226
parallel ./geotop1.226 ::: /home/joel/sim/wfj_P2//grid3/S*

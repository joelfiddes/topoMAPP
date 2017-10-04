#!/bin/bash
cd /home/joel/src/geotop/geotop1.226
parallel ./geotop1.226 ::: /home/joel/sim/ensembler_scale_sml/ensemble49/grid9/S*

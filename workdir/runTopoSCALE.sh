#!/bin/bash
echo $(basename $BASH_SOURCE)  'running........'
wd=$1
echo $wd
source $wd/toposat.ini

echo "precip pfactor used:" $pfactor

# Returns number of cells in ERA-Grid extent"
ncells=$(Rscript getRasterDims.R $wd spatial/eraExtent.tif) 
echo "ERA-Grid cells to run= " $wd/grid*


# compute elevations of each box and write out - NEED another way to do this, too long.
echo "Computing ERA-grid box elevations."
#Rscript eraBoxEle.R $wd 'predictors/ele.tif' 'spatial/eraExtent.tif'\
# get from surface gp field instaeda
Rscript getGridEle.R $wd 

echo '========================================================='
echo 'RUN TOPOSCALE'
echo '========================================================='
# Run toposcale
for Ngrid in $(seq 1 $ncells); do
	gridpath=$wd'/grid'$Ngrid
 	if [ ! -d "$gridpath" ]; then
   	echo "Grid "$Ngrid" has been removed because it contained no points. Now processing "$Ngrid+1
   	continue
 	fi
	echo "Running TopoSCALE GRID" $Ngrid 

	# Add eleDiff to listpoints
	Rscript boxMetadata.R $gridpath $Ngrid

	 Rscript tscale_plevel.R $gridpath $Ngrid 'rhumPl'
	 Rscript tscale_plevel.R $gridpath $Ngrid 'tairPl'
	 Rscript tscale_plevel.R $gridpath $Ngrid 'uPl'
	 Rscript tscale_plevel.R $gridpath $Ngrid 'vPl'
	# Rscript tscale_rhum.R $gridpath $Ngrid 
	# Rscript tscale_tair.R $gridpath $Ngrid
	# Rscript tscale_windu.R $gridpath $Ngrid
	# Rscript tscale_windv.R $gridpath $Ngrid

	Rscript tscale_sw.R $gridpath $Ngrid FALSE $tz #TRUE requires svf as does more computes terrain/sky effects
	Rscript tscale_lw.R $gridpath $Ngrid $svfCompute
	Rscript tscale_p.R $gridpath $Ngrid $pfactor
done



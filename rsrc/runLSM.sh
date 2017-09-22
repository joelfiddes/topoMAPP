#!/bin/bash
echo $(basename $BASH_SOURCE)  'running........'
wd=$1
echo $wd
source $wd/toposat.ini

#========================================================================
#               make batch file
#========================================================================
# Returns number of cells in ERA-Grid extent"
ncells=$(Rscript getRasterDims.R $wd spatial/eraExtent.tif) 
echo "Setting up simulation directories for $ncells  ERA-Grids" 

# set up sim directoroes #and write metfiles
for Ngrid in $(seq 1 $ncells); do
	
	gridpath=$wd'/grid'$Ngrid

	if [ ! -d "$gridpath" ]; then
   	echo "Grid "$Ngrid" has been removed because it contained no points. Now processing "$Ngrid+1
   	continue
 	fi

 	echo "Simulations grid" $Ngrid "running"
	cd $gridpath
	batchfile=batch.txt
	sim_entries=$gridpath/S*
	echo 'cd ' $lsmPath > $batchfile
	echo 'parallel' ./$lsmExe ' ::: ' $sim_entries >> $batchfile
	chmod u+x $batchfile
	./$batchfile
done
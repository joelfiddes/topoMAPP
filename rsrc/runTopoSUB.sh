source $wd/toposat.ini



# Returns number of cells in ERA-Grid extent"
ncells=$(Rscript getRasterDims.R $wd spatial/eraExtent.tif) 
echo "ERA-Grid cells= " $ncells 

# Run toposub on each ERA grid
for Ngrid in $(seq 1 $ncells); do
	gridpath=$wd'grid'$Ngrid
	echo "Processing ERA-grid" $Ngrid
	echo $gridpath
	Rscript toposub.R $gridpath $samples $Ngrid
done
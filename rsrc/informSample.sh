source $wd/toposat.ini

# Returns number of cells in ERA-Grid extent"
ncells=$(Rscript getRasterDims.R $wd spatial/eraExtent.tif) 
echo "Setting up simulation directories for $ncells  ERA-Grids" 

# set up sim directoroes #and write metfiles
for Ngrid in $(seq 1 $ncells); do
gridpath=$wd'/grid'$Ngrid
Rscript toposub_post_1.R $gridpath $samples $file1 $targV
Rscript toposub_pre_inform.R $gridpath $samples $targV $svfCompute
done
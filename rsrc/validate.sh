source $wd/toposat.ini
# magst, swe

# Returns number of cells in ERA-Grid extent"
ncells=$(Rscript getRasterDims.R $wd spatial/eraExtent.tif) 
echo "Setting up simulation directories for $ncells  ERA-Grids" 

# set up sim directoroes #and write metfiles
for Ngrid in $(seq 1 $ncells); do
	gridpath=$wd'/grid'$Ngrid
	Rscript validate.R $valDat $modDat $magstCol  $lonCol $latCol $gridpath
done
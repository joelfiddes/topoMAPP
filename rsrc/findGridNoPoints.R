# # re define ncells here based on occurances of grid* directoriers after removals
# grid_dirs = glob.glob(wd +"/grid*")
# ncells = len(grid_dirs)
# logging.info( " This simulation now contains ", ncells, " grids" )
# logging.info( " grids to be computed " + str(grid_dirs) )

# + LAST SECTION OF MAKELISPOINTS2.R

# Test if grid contains points and remove if not this needs toHAPPEN AT BEGINNING OF NGRID LOOP
require(raster)
rst <- raster("/home/joel/sim/test_points/spatial/eraExtent.tif")
shp  = shapefile("/home/joel/data/imis/gis/IMIS_GR.shp")

# replace values 1: ncell this is the grids index
values(rst)<- 1:ncell(rst)
extract(rst,shp)
ids = sort(unique(extract(rst,shp)))
gridsout <- paste0("grid", ids)
cat(gridsout)


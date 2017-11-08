library(MODIStsp) 

args = commandArgs(trailingOnly=TRUE)
gui=args[1]
options_file=args[2]
shp=args[3]

MODIStsp(gui = gui, options_file = options_file, spatial_file_path = shp ) 
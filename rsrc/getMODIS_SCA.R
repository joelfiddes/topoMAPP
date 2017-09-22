require(MODIStsp) 

args = commandArgs(trailingOnly=TRUE)
gui=args[1]
options_file=args[2]

MODIStsp(gui = gui, options_file = options_file) 
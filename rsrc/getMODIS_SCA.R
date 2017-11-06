require(MODIStsp) 

args = commandArgs(trailingOnly=TRUE)
gui=args[1]
options_file=args[2]
modisDescript <- packageDescription('MODIStsp')
print(modisDescript)
MODIStsp(gui = gui, options_file = options_file) 
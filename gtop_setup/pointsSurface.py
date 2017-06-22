#!/usr/bin/env python

""" This module extracts surface properties from predictors/surface.tif based on point locations.
 
Example:   
      as import: 


Attributes:

Todo:

"""
path2script = "./rsrc/pointsSurface.R"

# main
def main(wd):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd])

# functions
def run_rscript_stdout(path2script , args):
    """ Function to define comands to run an Rscript. Returns an object. """
    import subprocess
    command = 'Rscript'
    cmd     = [command, path2script] + args
    print("Running:" + str(cmd))
    x = subprocess.check_output(cmd, universal_newlines=True)
    return(x)

def run_rscript_fileout(path2script , args):
    """ Function to define comands to run an Rscript. Outputs a file. """
    import subprocess
    command = 'Rscript'
    cmd     = [command, path2script] + args
    print("Running:" + str(cmd))
    subprocess.check_output(cmd)
 
# calling main
if __name__ == '__main__':
    import sys
    wd    = sys.argv[1]
    main(wd)




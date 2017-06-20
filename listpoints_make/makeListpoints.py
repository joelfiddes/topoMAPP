#!/usr/bin/env python

""" This module creats a 'listpoints' file for all points contained within an ERA-grid.
 
Example:   

    as import: 

        from getERA import prepSims as sim
        sim.main(wd)

Attributes:

Todo:

"""
path2script = "./rsrc/makeListpoints.R"

# main
def main(gridpath, pointsFile, pkCol, lonCol, latCol):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[gridpath, pointsFile, pkCol, lonCol, latCol])
    
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
    gridpath    = sys.argv[1]
    pointsFile  = sys.argv[2]
    pkCol       = sys.argv[3]
    lonCol      = sys.argv[4]
    latCol      = sys.argv[5]
    main(gridpath, pointsFile, pkCol, lonCol, latCol)

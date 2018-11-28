#!/usr/bin/env python

""" This module preprocesses creates simulation directory for every ERA-grid in domain and cookie-cuts the predictors with each ERA-grid.
 
Example:   
        as script:
        $ python prepSims.py "/home/joel/sim/topomap_test"/predictors/ele.tif" "latN""

        or, as import: 

        from getERA import prepSims as sim
        sim.main(wd)

Attributes:
    wd = "/home/joel/sim/topomap_test/"
    plotshp = TRUE

Todo:

"""
path2script = "./rsrc/prepareSims.R"

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
    wd         = sys.argv[1]
    main(wd)

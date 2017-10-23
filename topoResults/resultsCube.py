#!/usr/bin/env python

""" This module preprocesses ERA-Interim data, units, accumulated to instantaneous values and timestep interpolation for 6 h to 3 h values.
 
Example:   
        as import: 

        from getERA import era_prep as prep
        prep.main(wd, config['main']['startDate'], config['main']['endDate'])


Attributes:
    wd = "/home/joel/sim/topomap_test/"
    plotshp = TRUE

Todo:

"""
path2script = "./rsrc/resultsCube.R"

# main
def main(gridpath):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[gridpath])
    
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
    gridpath         = sys.argv[1]

    main(gridpath)

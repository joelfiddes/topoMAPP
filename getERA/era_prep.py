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
path2script = "./rsrc/toposcale_pre2.R"

# main
def main(wd, startDate, endDate):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd, startDate, endDate])
    
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
    startDate  = sys.argv[2]
    endDate    = sys.argv[3]
    main(wd, startDate, endDate)

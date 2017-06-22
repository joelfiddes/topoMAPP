#!/usr/bin/env python

""" This module prepares a meteo file for every simulation point/sample
 
Example:   
      as import: 


Attributes:

Todo:
 - move u/v conversion to 'TOPOSCALE'
 - move tair conversion to toposcale
 - write as SMET format (probably best whole module moves to toposcale, output of toposcale is a smet file)
 - move listpoints and horizon stuff to separate modules
"""
path2script = "./rsrc/setupSim.R"

# main
def main(wd, svfComp):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd, svfComp])

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
    svfComp  = sys.argv[2]

    main(wd, svfComp)




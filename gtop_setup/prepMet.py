#!/usr/bin/env python

""" This module prepares a meteo file for every simulation point/sample
 
Example:   
      as import: 


Attributes:
tscale - scales airtemperature with additive factor
pscale - scales precip with a multiplicative factor

Todo:
 - move u/v conversion to 'TOPOSCALE'
 - move tair conversion to toposcale
 - write as SMET format (probably best whole module moves to toposcale, output of toposcale is a smet file)
 - move listpoints and horizon stuff to separate modules
"""
path2script = "./rsrc/setupSim.R"

# main
def main(wd, svfComp, tscale,pscale, swscale, lwscale):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd, svfComp, tscale, pscale, swscale,lwscale])

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
    tscale  = sys.argv[3]
    pscale  = sys.argv[4]
    swscale  = sys.argv[5]
    lwscale  = sys.argv[6]
    main(wd, svfComp, tscale,pscale, swscale, lwscale)




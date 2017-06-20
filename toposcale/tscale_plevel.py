#!/usr/bin/env python

""" This module computes atmospheric fields for a given elevation at the earths surface from pressure levvel data
 
Example:   
      as import: 

        import tscale_plevel as tscale
        tscale.main(gridpath, Ngrid, 'rhumPl')

Attributes:

Todo:

"""
path2script = "./rsrc/tscale_plevel.R"

# main
def main(wd, nbox, var):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd, nbox, var])

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
    nbox  = sys.argv[2]
    var   = sys.argv[3]
    main(wd, nbox, var)




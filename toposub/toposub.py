#!/usr/bin/env python

""" This module runs toposub
 
Example:   
      as import: 


Attributes:$gridpath $samples $Ngrid

Todo:

"""
path2script = "./rsrc/toposub.R"

# main
def main(gridpath, samples):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[gridpath, samples])

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
    gridpath           = sys.argv[1]
    samples         = sys.argv[2]
    main(gridpath, samples)

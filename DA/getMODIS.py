#!/usr/bin/env python

""" This module retrives MODIS fSCA product based on options file (DA/updateOptions.sh.
 
Example:   
      as import: 


Attributes:

Todo:

"""
path2script = "./rsrc/getMODIS_SCA.R"

# main
def main(gui , options_file):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[gui , options_file])

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
    gui          = sys.argv[1]
    options_file = sys.argv[2]
    main(gui , options_file)




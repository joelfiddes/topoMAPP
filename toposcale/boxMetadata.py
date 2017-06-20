#!/usr/bin/env python

""" This module computes ele diff between box and each listpoints member and long/lat of box centre
 
Example:   
      as import: 

Attributes:

Todo:

"""
path2script = "./rsrc/boxMetadata.R"

# main
def main(wd, nbox):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd, nbox])

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
    main(wd, nbox)




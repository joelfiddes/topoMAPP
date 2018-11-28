#!/usr/bin/env python

""" This module computes svf
 
Example:   
        as script:
        $ python computeTopo.py "/home/joel/sim/topomap_test/" "FALSE"

        or, as import: 

        import computeTopo as topo
        topo.main(args)


Attributes:
    wd = "/home/joel/sim/topomap_test/"
    angles = number of search angles
    dist = search distance in m

Todo:

"""
path2script = "./rsrc/computeSVF.R"

# main
def main(wd, angles, dist):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd, angles, dist])

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
    wd          = sys.argv[1]
    angles        = sys.argv[2]
    dist	= sys.argv[3]
   
    main(wd, angles, dist)


#!/usr/bin/env python

""" This module returns one of 4 extent elements (latN, latS, lonW, lonE) based on input raster.
 
Example:   
        as script:
        $ python getExtent.py "/home/joel/sim/topomap_test/predictors/ele.tif" "latN"

        or, as import: 

        import getExtent as ext
        ext.main("/home/joel/sim/topomap_test/predictors/ele.tif" , "latN")


Attributes:
    wd = "/home/joel/sim/topomap_test/"
    plotshp = TRUE

Todo:

"""
path2script = "./rsrc/extractEraBbox.R"

# main
def main(file, coordID, coord):
    """Main entry point for the script."""
    #print "Obtaining " + coord + " from " + elePath
    x = run_rscript_stdout(path2script,[elePath, coord, coordID])
    return(x)

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
    elePath         = sys.argv[1]
    coordID = sys.argv[2]
    coord = sys.argv[3]
    main(file, coordID, coord)

#!/usr/bin/env python

""" This module returns dimensions of a raster object. It ios generally used to quantify number of ERA-grid  cells
 
Example:   
        as script:
        $ python getExtent.py "/home/joel/sim/topomap_test/predictors/ele.tif" "latN"

        or, as import: 

        import getExtent as ext
        ext.main("/home/joel/sim/topomap_test/predictors/ele.tif" , "latN")


Attributes:

Todo:

"""
path2script = "./rsrc/findGridsWithPoints.R"

# main
def main(wd,rst, shp):
    """Main entry point for the script."""
    x = run_rscript_stdout(path2script,[wd,rst, shp])
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
    wd= sys.argv[1]
    rst         = sys.argv[2]
    shp = sys.argv[3]
   
    main(wd, rst, shp)

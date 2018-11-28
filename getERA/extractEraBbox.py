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
def main(file, coordID, lonw,lone, lats, latn):
    """Main entry point for the script."""
    x = run_rscript_stdout(path2script,[file, coordID, lonw,lone, lats, latn])
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
    file         = sys.argv[1]
    coordID = sys.argv[2]
    lonw= sys.argv[3]
    lone= sys.argv[4]
    lats= sys.argv[5]
    latn= sys.argv[6]
    main(file, coordID, lonw,lone, lats, latn)

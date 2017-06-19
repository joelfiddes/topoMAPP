#!/usr/bin/env python

""" This module retrieves dem from https://urs.earthdata.nasa.gov based on extent of positions 
listed in a 3 column points file (pk, lon, lat).
parse credentials file ~/.netrc to get required user/pwd.
setup user here: https://urs.earthdata.nasa.gov/profile
 
Example:   
        as script:
        $ python makeShape.py "/home/joel/sim/topomap_test/" "/home/joel/data/GCOS/points_all.txt" 2 3

        or, as import: 

        import makeShape as shp
        shp.main("/home/joel/sim/topomap_test/" , "/home/joel/data/GCOS/points_all.txt", str(2), str(3))

Attributes:
    wd = "/home/joel/sim/topomap_test/"
    demDir = "/home/joel/data/DEM/srtm"
    grid = 0.75
    pointsFile = "/home/joel/data/GCOS/points_all.txt"
    loncol = 2
    latcol = 3

Todo:

"""
path2script = "./rsrc/makeShape.R"

# main
def main(wd, pointsFile, loncol, latcol):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd, pointsFile, loncol, latcol])


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
    wd         = sys.argv[1]
    pointsFile = sys.argv[2]
    loncol     = sys.argv[3]
    latcol     = sys.argv[4] 
    main(wd, pointsFile, loncol, latcol)




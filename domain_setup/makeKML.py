#!/usr/bin/env python

""" This module retrieves dem from https://urs.earthdata.nasa.gov based on extent of positions 
listed in a 3 column points file (pk, lon, lat).
parse credentials file ~/.netrc to get required user/pwd.
setup user here: https://urs.earthdata.nasa.gov/profile
 
Example:   
        as script:
        $ python makeKML.py "/home/joel/sim/topomap_test/" "/home/joel/sim/topomap_test/predictors/ele.tif" "shape" "/home/joel/sim/topomap_test/spatial/extent

        or, as import: 

        import makeKML as kml
        kml.main("/home/joel/sim/topomap_test/", "/home/joel/sim/topomap_test/predictors/ele.tif", "shape", "/home/joel/sim/topomap_test/spatial/extent")


Attributes:
    wd = "/home/joel/sim/topomap_test/"
    plotshp = TRUE

Todo:

"""
path2script = "./rsrc/makeKML.R"

# main
def main(wd, file, outFormat, outPath):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd, file, outFormat, outPath])


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
    file        = sys.argv[2]
    outFormat   = sys.argv[3]
    outPath     = sys.argv[4]
   
    main(wd, file, outFormat, outPath)




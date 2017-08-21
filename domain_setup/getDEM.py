#!/usr/bin/env python

""" This module retrieves dem from https://urs.earthdata.nasa.gov based on extent of positions 
listed in a 3 column points file (pk, lon, lat).
parse credentials file ~/.netrc to get required user/pwd.
setup user here: https://urs.earthdata.nasa.gov/profile
 
Example:   
        as script:
        $ python getDEM_points_test.py "/home/joel/sim/topomap_test/" "/home/joel/data/DEM/srtm" 0.75 "/home/joel/data/GCOS/points_all.txt" 2 3

        or, as import: 

        import getDEM_points as gdem
        gdem.main("/home/joel/sim/topomap_test/" ,"/home/joel/data/DEM/srtm" ,0.75, "/home/joel/data/GCOS/points_all.txt", 2, 3)

Attributes:
    wd = "/home/joel/sim/topomap_test/"
    demDir = "/home/joel/data/DEM/srtm"
bbox = 

Todo:

"""
path2script = "./rsrc/getDEM.R"

# main
def main(wd, demDir, lonw, lats, lone, latn):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd, demDir, str(lonw), str(lats), str(lone), str(latn)])


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
    demDir      = sys.argv[2]
    lonw        = sys.argv[3]
    lats        = sys.argv[4]
    lone        = sys.argv[5]
    latn        = sys.argv[6]

    main(wd, demDir, lonw, lats, lone, latn)




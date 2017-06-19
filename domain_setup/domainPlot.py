#!/usr/bin/env python

""" This module retrieves dem from https://urs.earthdata.nasa.gov based on extent of positions 
listed in a 3 column points file (pk, lon, lat).
parse credentials file ~/.netrc to get required user/pwd.
setup user here: https://urs.earthdata.nasa.gov/profile
 
Example:   
        as script:
        $ python domainPlot.py "/home/joel/sim/topomap_test/" "TRUE"

        or, as import: 

        import domainPlot as dplot
        dplot.main("/home/joel/sim/topomap_test/" , "TRUE")


Attributes:
    wd = "/home/joel/sim/topomap_test/"
    plotshp = TRUE

Todo:

"""
path2script = "./rsrc/domainPlot.R"

# main
def main(wd, plotshp):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[wd, plotshp])

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
    plotshp = sys.argv[2]
   
    main(wd, plotshp)




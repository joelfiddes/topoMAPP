#!/usr/bin/env python

""" This module retrives MODIS fSCA product based on options file 
#https://github.com/lbusett/MODIStsp 
use to set params: Rscript getMODIS_SCA.R TRUE $options_file 
docs MODIS SCA https://modis-snow-ice.gsfc.nasa.gov/uploads/C6_MODIS_Snow_User_Guide.pdf script gets extent from DEM and sets Options for SCA download

# MODIS SA CODES
#
# 0-100=NDSI snow 200=missing data
# 201=no decision
# 211=night
# 237=inland water 239=ocean
# 250=cloud
# 254=detector saturated 255=fill

Example:   
      as import: 


Attributes:

Todo:

"""
path2script = "./rsrc/getMODIS.R"

# main
def main(options_file ,shp):
    """Main entry point for the script."""
    run_rscript_fileout(path2script,[options_file, shp])

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
    options_file = sys.argv[1]
    shp = sys.argv[2]
    main(options_file, shp)




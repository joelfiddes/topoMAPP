# obtain MODIS SCA as independent process from main script - convenient to run these jobs more flexibly
# takes path to config ini file as sole arg

from configobj import ConfigObj
config = ConfigObj(sys.argv[1])
wd = config["main"]["wd"]

# generate shapefile from sim domain to define MODIS download aoi
inRst = wd + "/spatial/eraExtent.tif"
outShp = wd + "/spatial/eraExtent.shp" # does not yet exist

# process creates shp file
cmd = ["Rscript", "./rsrc/rst2shp.R" , inRst, outShp]
subprocess.check_output(cmd)

import TMsca
TMsca.main(config, shp = outShp )
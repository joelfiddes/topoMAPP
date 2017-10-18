#!/usr/bin/env python
import os
import pandas as pd
import time
import sys

#===============================================================================================
# PARAMETERS TO SET

root = "/home/joel/sim/ensembler_testRadflux/"
inifile="test.ini"
initdir='/home/joel/sim/test_radflux'
initgrid = "2"
N = 100# number of ensemble memebers
#===============================================================================================


# Timer
start_time = time.time()


# start ensemble runs
print "Running ensemble members: " + str(N)

#generate ensemble
os.system("Rscript rsrc/ensemGen.R " + str(N))

# read in csv as pd data
df = pd.read_csv("ensemble.csv")

# Assimilation cycle loop start here


#loop over ensemble members
for i in range(0,N):
	print "Running ensemble member:" + str(i)
	pbias = df['pbias'][i]
	tbias = df['tbias'][i]
	lwbias = df['lwbias'][i]
	swbias = df['swbias'][i]

	print "[INFO]: Config ensemble members"
	from configobj import ConfigObj
	config = ConfigObj(inifile)
	config.filename = inifile
	config["main"]["wd"]  = root + "ensemble" + str(i) + "/"
	config["da"]["pscale"] = pbias #factor to multiply precip by
	config["da"]["tscale"] = tbias #factor to add to temp
	config["da"]["swscale"] = swbias
	config["da"]["lwscale"] = lwbias
	config['modis']['getMODISSCA'] = "FALSE"
	config["main"]["initSim"]  = 'TRUE'
	config['main']['initDir'] = initdir
	config['toposub']['inform'] = 'FALSE'
	config['main']['initGrid'] = initgrid
	config.write()

	print "[INFO]: Config settings used"
	print(config)

	print "[INFO]: Running topomapp_main.py"
	os.system("python topomapp_main.py " + inifile)


print("[INFO]: %f minutes for run of ensemble members" % round((time.time()/60 - start_time/60),2))

# Collect results of fca
# Collect obs of fca
# Do analysis
# Update ppars
# next assimilation cycle

#Report starts 
#!/usr/bin/env python
import os
import pandas as pd
import time
import sys

#set root
root = "/home/joel/sim/ensembler3/"
# Timer
start_time = time.time()

#ensure exists
os.system("python writeConfig.py")

# Do norm run - doesnt work as needs different config settings (initSim = FALSE)
# if len(sys.argv) == 2 and sys.argv[1] == 'NORM':
# 	print "Running NORMAL simulation"
# 	pbias = 1
# 	tbias = 0

# 	from configobj import ConfigObj
# 	config = ConfigObj("topomap.ini")
# 	config.filename = "topomap.ini"
# 	config["main"]["wd"]  = root + "ensemble_norm/"
# 	config["main"]["initSim"]  = 'TRUE'
# 	config["da"]["pscale"] = pbias #factor to multiply precip by
# 	config["da"]["tscale"] = tbias #factor to add to temp
# 	config['modis']['getMODISSCA'] = "TRUE"
# 	config.write()

# 	print "[INFO]: Config settings used"
# 	print(config)

# 	print "[INFO]: Running TopoMap"
# 	os.system("python code_da.py")

# 	print("[INFO]: %f minutes for run of NORM" % round((time.time()/60 - start_time/60),2))


# check norm exists
# if os.path.isdir(root + "/ensemble_norm") == False:
# 	print "No ensemble_norm, run <ensembleRun.py NORM> to generate.. ABORTING"
# 	exit()
# elif os.path.isdir(root + "ensemble_norm") == True:
# 	print "ensemble_norm found"	

# start ensemble runs
print "Running ensemble members"

# number of ensemble memebers
N = 100

#generate ensemble
os.system("Rscript rsrc/ensemGen.R " + str(N))

# read in csv as pd data
df = pd.read_csv("ensemble.csv")

# Assimilation cycle loop start here


#loop over ensemble memebers
for i in range(0,N):
	print "Running ensemble member:" + str(i)
	pbias = df['pbias'][i]
	tbias = df['tbias'][i]

	print "[INFO]: Config ensemble members"
	from configobj import ConfigObj
	config = ConfigObj("topomap.ini")
	config.filename = "topomap.ini"
	config["main"]["wd"]  = root + "ensemble" + str(i) + "/"
	config["da"]["pscale"] = pbias #factor to multiply precip by
	config["da"]["tscale"] = tbias #factor to add to temp
	config['modis']['getMODISSCA'] = "FALSE"
	config["main"]["initSim"]  = 'TRUE'
	config['main']['initDir'] = '/home/joel/sim/da_test2'
	config['toposub']['inform'] = 'FALSE'


	config.write()

	print "[INFO]: Config settings used"
	print(config)

	print "[INFO]: Running code_da.py"
	os.system("python code_da.py")


print("[INFO]: %f minutes for run of ensemble members" % round((time.time()/60 - start_time/60),2))

# Collect results of fca
# Collect obs of fca
# Do analysis
# Update ppars
# next assimilation cycle

#Report starts 
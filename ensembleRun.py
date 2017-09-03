#!/usr/bin/env python
import os

#ensure exists
os.system("python writeConfig.py")

#run norm
#os.system("python code_bbox.py")

# this is an ensemble simulation generator
# 3 vectors
# loop here to generate ensemble
p=2,3, 0.5
for i in p:
	print "[INFO]: Config ensemble member"
	from configobj import ConfigObj
	config = ConfigObj("topomap.ini")
	config.filename = "topomap.ini"
	config["main"]["wd"]  = "/home/joel/sim/wfj_P" + str(i) + "/"
	config["da"]["pscale"] = 10 #factor to multiply precip by
	config["da"]["tscale"] = 0 #factor to add to temp
	config.write()

	print "[INFO]: Config settings used"
	print(config)

	print "[INFO]: Running TopoMap"
	os.system("python code_bbox.py")

t = 1,2,3,-1,-2,-3
for i in t:
	print "[INFO]: Config ensemble member"
	from configobj import ConfigObj
	config = ConfigObj("topomap.ini")
	config.filename = "topomap.ini"
	config["main"]["wd"]  = "/home/joel/sim/wfj_T" + str(i) + "/"
	config["da"]["pscale"] = 10 #factor to multiply precip by
	config["da"]["tscale"] = 0 #factor to add to temp
	config.write()

	print "[INFO]: Config settings used"
	print(config)

	print "[INFO]: Running TopoMap"
	os.system("python code_bbox.py")




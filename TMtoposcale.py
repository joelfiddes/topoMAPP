#!/usr/bin/env python


"""
docstring
"""

import os

def main(wd, Ngrid, config):

	gridpath = Ngrid
	fname1 = gridpath + "/tPoint.txt"

	if os.path.isfile(fname1) == False: #NOT ROBUST
		print fname1
		#path=wd
		#file="tPoint.txt"
		#x=fileSearch.search(path, file)
		#if x != 1: #NOT ROBUST

		# retrieve era grid index from Ngrid string
		import re
		s = os.path.basename(Ngrid)
		Ngrid2 = re.split('(\d+)', s)[1]
		

		from toposcale import getGridEle as gele
		gele.main(wd)

		from toposcale import boxMetadata as box
		box.main(gridpath, str(Ngrid2))

		from toposcale import tscale_plevel as plevel
		
		from joblib import Parallel, delayed 
		import multiprocessing 
		jobs=["rhumPl","tairPl","uPl","vPl"]
		Parallel(n_jobs=4)(delayed(plevel.main)(gridpath, str(Ngrid2), i) for i in jobs)

		# plevel.main(gridpath, str(Ngrid2), "rhumPl")
		# plevel.main(gridpath, str(Ngrid2), "tairPl")
		# plevel.main(gridpath, str(Ngrid2), "uPl")
		# plevel.main(gridpath, str(Ngrid2), "vPl")

		from toposcale import tscale_sw as sw
		sw.main( gridpath, str(Ngrid2), config["toposcale"]["swTopo"], config["main"]["tz"]) #TRUE requires svf as does more computes 

		from toposcale import tscale_lw as lw
		lw.main( gridpath, str(Ngrid2), config["toposcale"]["svfCompute"]) #TRUE requires svf as does more computes terrain/sky effects
		
		from toposcale import tscale_p as p
		p.main( gridpath, str(Ngrid2), config["toposcale"]["pfactor"])

			#else:
				#print "[INFO]: Grid "+ str(Ngrid2) + " has been removed because it contained no points. Now processing grid" + str(Ngrid2)+1
	else:
		print "[INFO]: TopoSCALE already run for " + Ngrid


# calling main
if __name__ == '__main__':
	import sys
	wd      = sys.argv[1]
	Ngrid      = sys.argv[2]
	config = sys.ar[3]
	main(wd, Ngrid, config)
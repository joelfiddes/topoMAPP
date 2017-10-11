path=wd
file="tPoint.txt"
x=fileSearch.search(path, file)
if x != 1: #NOT ROBUST



	from toposcale import getGridEle as gele
	gele.main(wd)

	# set up sim directoroes #and write metfiles
	for Ngrid in range(1,int(ncells)+1):
		gridpath = wd +"/grid"+ str(Ngrid)

		if os.path.exists(gridpath):
			print "[INFO]: running toposcale for grid " + str(Ngrid)

			from toposcale import boxMetadata as box
			box.main(gridpath, str(Ngrid))

			from toposcale import tscale_plevel as plevel
			plevel.main(gridpath, str(Ngrid), "rhumPl")
			plevel.main(gridpath, str(Ngrid), "tairPl")
			plevel.main(gridpath, str(Ngrid), "uPl")
			plevel.main(gridpath, str(Ngrid), "vPl")

			from toposcale import tscale_sw as sw
			sw.main( gridpath, str(Ngrid), config["toposcale"]["swTopo"], config["main"]["tz"]) #TRUE requires svf as does more computes 

			from toposcale import tscale_lw as lw
			lw.main( gridpath, str(Ngrid), config["toposcale"]["svfCompute"]) #TRUE requires svf as does more computes terrain/sky effects
			
			from toposcale import tscale_p as p
			p.main( gridpath, str(Ngrid), config["toposcale"]["pfactor"])

		else:
			print "[INFO]: Grid "+ str(Ngrid) + " has been removed because it contained no points. Now processing grid" + str(Ngrid)+1
else:
	print "[INFO]: TopoSCALE already run"
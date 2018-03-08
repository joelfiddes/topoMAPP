import os
import logging

def main(config, ensembRun):
#====================================================================
#	Initialise run: this can be used to copy meteo and surfaces to a 
# 	new sim directory. 
# 	Main application is in ensemble runs where only sim dir are 
#	copied (eg no rerun toposcale or toposub needed)
#====================================================================
	# notifications
	logging.info("initialising " + config['main']['wd'] + " from " + config["main"]["initDir"])
	logging.info("Copying Grid" + config["main"]["initGrid"])

	# Creat wd dir if doesnt exist
	if not os.path.exists(config['main']['wd']):
		os.makedirs(config['main']['wd'])

	if ensembRun == False:

		# copy directory "eraDat"
		src = config["main"]["initDir"] + "/eraDat"
		dst = config['main']['wd']
		cmd = "cp -r %s %s"%(src,dst)
		os.system(cmd)

		# copy directory "predictors"
		src = config["main"]["initDir"] + "/predictors"
		cmd = "cp -r %s %s"%(src,dst)
		os.system(cmd)

		# copy directory "spatial"
		src = config["main"]["initDir"] + "/spatial"
		cmd = "cp -r %s %s"%(src,dst)
		os.system(cmd)

		# copies grids can be one or all
		src = config["main"]["initDir"] + "/grid" + config["main"]["initGrid"]
		cmd = "cp -r  %s %s"%(src,dst)
		os.system(cmd)

	# currently only supports cop[ying of one grid
	if ensembRun == True & config["ensemble"]["valMode"] == "FALSE":
		#if config["main"]["initGrid"] == "*" # could use this for supporting copitying of all files
		# copies grids can be one or all
		
		# make new dierectory
		dst = config['main']['wd'] + "/grid" + config["main"]["initGrid"]
		cmd = "mkdir  %s"%(dst)
		os.system(cmd)

		# copy sim dirs only
		src = config["main"]["initDir"] + "/grid" + config["main"]["initGrid"] +"/S*"
		dst = config['main']['wd'] + "/grid" + config["main"]["initGrid"]
		cmd = "cp -r  %s %s"%(src,dst)
		os.system(cmd)

	if ensembRun == True & config["ensemble"]["valMode"] == "TRUE":

		# function that maps valshp points to sample ids and returns full path to sample dir as list
		cmd = "Rscript ./rsrc/getSampleID.R " + config['main']['wd'] + "/grid" + config["main"]["initGrid"] + " " + config["ensemble"]["valShp"]
		a = subprocess.check_output(cmd, shell = "TRUE")
		b = a.split()
		# b is now list of src to send to cp command
		
		logging.info("In VALMODE, only copying samples: " + str(b)
			
		# make new dierectory
		dst = config['main']['wd'] + "/grid" + config["main"]["initGrid"]
		cmd = "mkdir  %s"%(dst)
		os.system(cmd)

		# copy sim dirs only
		src = b
		dst = config['main']['wd'] + "/grid" + config["main"]["initGrid"]
		cmd = "cp -r  %s %s"%(src,dst)
		os.system(cmd)

#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys
	config      = sys.argv[1]
	ensembRun = sys.argv[2]
	main(config, ensembRun)
#!/usr/bin/env python

"""

args1: full path to config.ini

example:
	python tmapp_setup.py "/home/caduff/sim/topomapptest/config.ini"


		tz is always 0 UTC as that is timezone of the data

TODO:
	still not clear what the start point is dem? ccords? era grid?
"""

import sys
import os
import subprocess
import logging
import os.path
#from listpoints_make import getRasterDims as dims
import glob
#import joblib
import numpy


#===============================================================================
#	Timer
#===============================================================================
import time
start_time = time.time()

#===============================================================================
#	Config setup
#===============================================================================
#os.system("python writeConfig.py") # update config DONE IN run.sh file
from configobj import ConfigObj
config = ConfigObj(sys.argv[1])
#config = ConfigObj("/home/joel/sim/topomapptest/config.ini")
wd = config["main"]["wd"]
tscale_root=config['main']['tscale_root']

#===============================================================================
#	DEM parameters
#===============================================================================
demRes = config["main"]["demRes"] # 1=30m 3=90m
chirpsP=config["main"]["chirpsP"]

#===============================================================================
#	Logging
#===============================================================================

logging.basicConfig(level=logging.DEBUG, filename=wd+"/logfile", filemode="a+",
                        format="%(asctime)-15s %(levelname)-8s %(message)s")


#===============================================================================
#	Creat wd dir if doesnt exist
#===============================================================================
#directory = os.path.dirname(wd)
if not os.path.exists(wd):
	os.makedirs(wd)
if not os.path.exists(wd + "/sim"):
	os.makedirs(wd + "/sim")

if not os.path.exists(wd + "/spatial"):
	os.makedirs(wd + "/spatial")

if not os.path.exists(wd + "/forcing"):
	os.makedirs(wd + "/forcing")

if not os.path.exists(wd + "/predictors"):
	os.makedirs(wd + "/predictors")

if not os.path.exists(wd + "/da"):
	os.makedirs(wd + "/da")
#ndvi_wd=wd + "/modis/ndvi"
#if not os.path.exists(ndvi_wd):
	#os.makedirs(ndvi_wd)

#===============================================================================
#	Announce wd
#===============================================================================
logging.info("----------------------- START SETUP -----------------------")
logging.info("Simulation directory: " + wd  )

#===============================================================================
#	Initialise run: this can be used to copy meteo and surfaces to a new sim directory.
# 	Main application is in ensemble runs
#===============================================================================
# if config["main"]["initSim"] == "TRUE":
# 	import TMinit
# 	TMinit.main(config, ensembRun=False)


#===============================================================================
# Copy config to simulation directory
#===============================================================================
#configfilename = os.path.basename(sys.argv[1])
#config.filename = wd +  "/" + configfilename
#config.write()

#===============================================================================
#	Retrieve DEM and compute slp/asp
#===============================================================================

# control statement to skip if "asp.tif" exist - indicator fileNOT ROBUST
# fname = wd + "/predictors/asp.tif"
# if os.path.isfile(fname) == False:

fname1 = wd + "/predictors/asp.tif"
fname2 = wd + "/predictors/slp.tif"
fname3 = wd + "/predictors/ele.tif"

if os.path.isfile(fname1) == False or os.path.isfile(fname2) == False or os.path.isfile(fname3) == False: #NOT ROBUST

	if not os.path.exists(wd + "predictors/ndvi.tif"):
		sys.exit("No NDVI file found at: " + wd + "predictors/ndvi.tif " +" please download from  https://clim-engine.appspot.com/") # see below MODIS for product details

		# copy preexisting dem
	if config["main"]["demexists"] == "TRUE":

		cmd = "mkdir " + wd + "/predictors/"
		os.system(cmd)
		src = config["main"]["dempath"]
		dst = wd +"/predictors/dem.tif"
		cmd = "cp -r %s %s"%(src,dst)
		os.system(cmd)

	if config["main"]["demexists"] == "FALSE":

		'''makes domain.shp that is used to download dem only, could alos now pass ccord directly to getDEM.R.
		If DEM is present missing or incorrect coords is not a problem'''
		if config['main']['runmode']=='grid':
			logging.info("create shp")
			cmd = ["Rscript", "./rsrc/makePoly.R" ,config["main"]["latN"],config["main"]["latS"],config["main"]["lonE"],config["main"]["lonW"], wd +"/spatial/domain.shp"] # n,s,e,w
			subprocess.check_output(cmd)

			fname = wd + "/predictors/ele.tif"
			if os.path.isfile(fname) == False:
				logging.info("Downloading DEM")
				cmd = ["Rscript", "./rsrc/getDEM.R" , wd, config["main"]["demdir"] , wd +"/spatial/domain.shp", demRes]
				subprocess.check_output(cmd)
			else:
				logging.info("DEM already downloaded")


		if config['main']['runmode']=='points':
			fname = wd + "/predictors/ele.tif"
			if os.path.isfile(fname) == False:
				logging.info("Downloading DEM")
				cmd = ["Rscript", "./rsrc/getDEM.R" , wd, config["main"]["demdir"] , config["main"]["pointsShp"], demRes]
				subprocess.check_output(cmd)
			else:
				logging.info("DEM already downloaded")

		if config['main']['runmode']=='points_sparse':
			fname = wd + "/predictors/ele.tif"
			if os.path.isfile(fname) == False:
				logging.info("Downloading DEM")
				cmd = ["Rscript", "./rsrc/getDEM_points.R" , wd, config["main"]["demdir"] , config["main"]["pointsShp"], demRes, config["main"]["pointsBuffer"]]
				subprocess.check_output(cmd)
			else:
				logging.info("DEM already downloaded")

		if config['main']['runmode']=='basins':
			fname = wd + "/predictors/ele.tif"
			if os.path.isfile(fname) == False:
				logging.info("Downloading DEM")
				cmd = ["Rscript", "./rsrc/getDEM.R" , wd, config["main"]["demdir"] , wd +"/basins/basins.shp", demRes]
				subprocess.check_output(cmd)
			else:
				logging.info("DEM already downloaded")


	# points topo is handled in main run routine now.

	#if config['main']['runmode']!='points': WHY THIS LINE?
	if config['main']['runmode']!='points_sparse':
			logging.info("Compute topo predictors")
			cmd = ["Rscript", "./rsrc/computeTopo.R" , wd, chirpsP]
			subprocess.check_output(cmd)

	else:
		logging.info("DEM downloaded and Topo predictors computed")
		print("DEM downloaded and Topo predictors computed")
#===============================================================================
#	Retrieve ERA
#===============================================================================
#import getMeteo.py

#===============================================================================
#	Retrieve MODIS
#===============================================================================
"""
Most MODIS retrieval api are quite unstable so current solution is:
- https://clim-engine.appspot.com/
- options
 - "remote sensing"
 -"MOSIS TERRA 16-days"
 - NDVI (250 m)
 - "mean"
 - "average conditions"
 - "1 Aug - 31 Aug"
 - full length of record

 This then returns mean August NDVI over entire record. Download a subset that
 is greater than footprint of domain and save as "predictors/ndvi.tif"

"""
# logging.info( "Retrieving MODIS NDVI")

# # Define grid AOI shp
# gridAOI = wd + "/spatial/extent.shp"
# cmd = ["Rscript", "./rsrc/rst2shp.R" , wd + "/predictors/ele.tif", gridAOI]
# subprocess.check_output(cmd)

# #need to run loop of five requests at set dates (can be fixed for now)
# mydates=["2001-08-12","2004-08-12","2008-08-12","2012-08-12"]#,"2016-08-12"]
# for date in mydates:
# 	# call bash script that does grep type stuff to update values in options file
# 	cmd = ["./modis/updateOptions.sh" , date , date, config["main"]["srcdir"]+"/modis/optionsNDVI.json", ndvi_wd]
# 	subprocess.check_output(cmd)

# 	# run MODIStsp tool
# 	cmd = ["Rscript", "./rsrc/getMODIS.R", config["main"]["srcdir"]+"/modis/optionsNDVI.json", gridAOI] #  able to run non-interactively now
# 	subprocess.check_output(cmd)

#===============================================================================
#	Setup cluster
#===============================================================================
"""
Set up cluster
 Args:
	[1] work dir
	[2] grid used by sim (0.25 = era5 0.5 = ensemble)
"""
if config['main']['runmode']=='grid':
	logging.info("Setup sim directories")

	if config["forcing"]["product"]=="ensemble_members":
		cmd = ["Rscript", "./rsrc/prepClust_EDA.R", wd, config['forcing']['grid'], config['forcing']['members']]
		subprocess.check_output(cmd)

	if config["forcing"]["product"]=="reanalysis":
		cmd = ["Rscript", "./rsrc/prepClust_HRES.R", wd, config['forcing']['grid']]
		subprocess.check_output(cmd)

if config['main']['runmode']=='points_sparse':
	logging.info("Setup point sim directories")
	cmd = ["Rscript", "./rsrc/prepClust_pointsSparse.R", wd, config['forcing']['grid']]
	subprocess.check_output(cmd)

if config['main']['runmode']=='basins':
	logging.info("Setup basin sim directories")
	if config["forcing"]["product"]=="reanalysis":
		cmd = ["Rscript", "./rsrc/prepClust_BASINS.R", wd, wd+'/basins/basins.shp']
		subprocess.check_output(cmd)

if config['main']['runmode']=='basinsBLIN':
	logging.info("Setup basin sim directories")
	if config["forcing"]["product"]=="reanalysis":
		cmd = ["Rscript", "./rsrc/prepClust_BASINS.R", wd, wd+'/basins/basins.shp']
		subprocess.check_output(cmd)
#===============================================================================
#	generate basin forcing
#  todo: calc p gradient here
#===============================================================================
if config['main']['runmode']=='basins':
	logging.info("Generate basin forcing")
	print("Generate basin forcing")
	cmd = ["Rscript", tscale_root+"/tscaleV2/toposcale/grid2basin_memSafe.R",wd]
	subprocess.check_output(cmd)

if config['main']['runmode']=='basinsBLIN':
	logging.info("Generate basin forcing")
	print("Generate basin forcing")
	cmd = ["Rscript", tscale_root+"/tscaleV2/toposcale/grid2basin2.R",wd]
	subprocess.check_output(cmd)
#===============================================================================
#	Start sims
#===============================================================================
""" Start sims
	- generate joblist that can be executed locally on n cores or sent to
	cluster
	"""
#logging.info("Generate joblist")
#cmd = ["Rscript", "./rsrc/joblist.R", wd]
#subprocess.check_output(cmd)

logging.info("Setup complete!")
logging.info(" %f minutes for setup" % round((time.time()/60 - start_time/60),2) )
print(" %f minutes for setup" % round((time.time()/60 - start_time/60),2) )

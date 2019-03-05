#!/usr/bin/env python

"""tmapp_run.py


Example:

	joel@joel-ThinkPad-T440p:~/src/tmapp2$ python tmapp_run.py /home/joel/sim/topomapptest/ g1m3 3


Attributes:

Todo:
    * limit tscale 1 to only a single yrear for efficiency
    * init ensemble memeber with existing listpoints only do 1*tscale 1*sim



"""

import sys
import os
import subprocess
import logging
from datetime import datetime, timedelta
from dateutil.relativedelta import *
import glob
from shutil import copyfile
import sys
import time


def main(wd, simdir, member):

	#===============================================================================
	#	Config setup
	#===============================================================================
	#os.system("python writeConfig.py") # update config DONE IN run.sh file
	from configobj import ConfigObj
	config = ConfigObj(wd+"/config.ini")

	tscale_root=config['main']['tscale_root'] # path to tscaleV2 directory
	#===============================================================================
	#	Logging
	#===============================================================================
	logging.basicConfig(level=logging.DEBUG, filename=wd+"/sim/"+ simdir+"/logfile", filemode="a+",
	                        format="%(asctime)-15s %(levelname)-8s %(message)s")

	#====================================================================
	#	Timer
	#====================================================================
	start_time = time.time()

	#===============================================================================
	#	make dirs
	#===============================================================================
	home = wd+"/sim/"+simdir
	if not os.path.exists(home + "/forcing"):
		os.makedirs(home + "/forcing")

	#===============================================================================
	#	Init ensemble memebers from memeber =1
	#===============================================================================
	'''copy 
	-listpoints

	'''

	if int(member) > 1:
		ngrid = simdir.split("m")[0]
		master= wd + '/sim/' + ngrid + 'm1'
		src=master +"/listpoints.txt" 
		dst= home+"/listpoints.txt"
		copyfile(src,dst)
		src=master +"/landcoverZones.txt" 
		dst= home+"/landcoverZones.txt"
		copyfile(src,dst)
		src=master +"/landform.tif" 
		dst= home+"/landform.tif"
		copyfile(src,dst)

	start = datetime.strptime(config['main']['startDate'], "%Y-%m-%d")
	end = datetime.strptime(config['main']['endDate'], "%Y-%m-%d")


	if int(member) == 1:
		#=========================  start of memeber 1 only section   ===============================================

		#===============================================================================
		#	Compute svf
		#===============================================================================
		logging.info( "Calculating SVF layer")
		cmd = ["Rscript", "./rsrc/computeSVF.R", home,str(6), str(500)]
		subprocess.check_output(cmd)

		#===============================================================================
		#	Compute surface
		#===============================================================================
		fname = home + "/predictors/surface.tif"
		if os.path.isfile(fname) == False:

			logging.info( "Calculating surface layer")
			cmd = ["Rscript",  "./rsrc/makeSurface.R",home,str(0.3)]
			subprocess.check_output(cmd)
		else:
			logging.info("Surface already computed!")
		#===============================================================================
		#	Run toposub 1
		#===============================================================================
		fname = home + "/listpoints.txt"
		if os.path.isfile(fname) == False:

			logging.info( "Run TopoSUB 1 ")
			cmd = ["Rscript",  "./rsrc/toposub.R",home,str(config['toposub']['nclust']), "TRUE"]
			subprocess.check_output(cmd)
			f = open(home + "/SUCCESS_TSUB1", "w")
		else:
			logging.info("TopoSUB already run!")
		#===============================================================================
		#	Run toposcale 1 - only 1 year
		#===============================================================================

		dateDiff=end-start

		'''check for complete forcing/meteo* files==nclust'''
		meteoCounter = len(glob.glob1(home+"/forcing/","*.csv"))

		if meteoCounter != int(config['toposub']['nclust']):
			""" run informed toposub on just one year data for efficiency"""
			if (dateDiff.days > 368):
				end = start+relativedelta(months=+12)
				endDate= str('{0:04}'.format(end.year))+"-"+str('{0:02}'.format(end.month))+"-"+str('{0:02}'.format(end.day))
				logging.info("Running short Toposcale from: " + config["main"]["startDate"] + " to " + endDate)



			# To control short toposcale run
			startTime=(
			str('{0:04}'.format(start.year))+"-"
			+str('{0:02}'.format(start.month))+"-"
			+str('{0:02}'.format(start.day))+" "
			+str('{0:02}'.format(start.hour))+":"
			+str('{0:02}'.format(start.minute))+":"
			+str('{0:02}'.format(start.second))
			)

			endTime=(
			str('{0:04}'.format(end.year))+"-"
			+str('{0:02}'.format(end.month))+"-"
			+str('{0:02}'.format(end.day))+" "
			+str('{0:02}'.format(end.hour))+":"
			+str('{0:02}'.format(end.minute))+":"
			+str('{0:02}'.format(end.second))
			)


			if config["forcing"]["product"]=="ensemble_members":

				logging.info( "Run TopoSCALE 1 ensembles")

				cmd = [
				"python",  
				tscale_root+"/tscaleV2/toposcale/tscale_run_ensemble.py",
				wd + "/forcing/", 
				home,home+"/forcing/" ,
				str(member),
				startTime,
				endTime
				]

			if config["forcing"]["product"]=="reanalysis":

				logging.info( "Run TopoSCALE 1 reanalysis")

				cmd = [
				"python",  
				tscale_root+"/tscaleV2/toposcale/tscale_run.py",
				wd + "/forcing/", 
				home,home+"/forcing/",
				startTime,
				endTime
				]

			subprocess.check_output(cmd)

			logging.info( "Convert met to geotop format...")
			files = os.listdir(home+"/forcing/")

			for file in files:
				cmd = ["Rscript",  "./rsrc/met2geotop.R",home+"/forcing/"+file]
				subprocess.check_output(cmd)
			f = open(home + "/SUCCESS_TSCALE1", "w")
		else:
			logging.info( "Toposcale 1 already run "+ config['toposub']['nclust']+ " meteo files found" )

		#===============================================================================
		#	Prepare sims (GEOTOP SPECIFIC)
		#===============================================================================
		''' check for geotop run complete files'''
		runCounter = 0
		for root, dirs, files in os.walk(home):
			for file in files:    
				if file.endswith('_SUCCESSFUL_RUN'):
					runCounter += 1

		if runCounter != int(config['toposub']['nclust']):



			logging.info( "prepare cluster sim directories")
			cmd = ["Rscript",  "./rsrc/setupSim.R", home]
			subprocess.check_output(cmd)

			logging.info( "Assign surface types")
			cmd = ["Rscript",  "./rsrc/modalSurface.R", home]
			subprocess.check_output(cmd)

			logging.info( "prepare geotop.inpts")
			cmd = ["Rscript",  "./rsrc/makeGeotopInputs.R", home , config["main"]["srcdir"]+ "/geotop/geotop.inpts" ,config["main"]["startDate"],endDate ]
			subprocess.check_output(cmd)

		#===============================================================================
		#	Simulate results - 1 year
		#===============================================================================
			sims = glob.glob(home+"/c0*")

			for sim in sims:
				logging.info( "run geotop" + sim)
				cmd = ["./geotop/geotop1.226", sim]
				subprocess.check_output(cmd)
			f = open(home + "/SUCCESS_SIM1", "w")
		else:
			logging.info( "Geotop 1 already run "+ config['toposub']['nclust']+ " _SUCCESSFUL_RUN files found" )
		#====================================================================
		# Informed sampling
		#====================================================================
		if config["toposub"]["inform"] == "TRUE":

			fname1 = home + "/landformsInform.pdf"
			if os.path.isfile(fname1) == False: #NOT ROBUST
			
				#logging.info( "TopoSUB **INFORM** run: ")

					# set up sim directoroes #and write metfiles

				logging.info( "postprocess results")
				cmd = ["Rscript",  "./rsrc/toposub_post.R", home, config['toposub']['nclust'] ,config['geotop']['file1'] ,config['geotop']['targV']]
				subprocess.check_output(cmd)

		#===============================================================================
		#	Run toposub 2
		#===============================================================================

				logging.info( "Run toposub informed")
				cmd = ["Rscript",  "./rsrc/toposub_inform.R", home , config['toposub']['nclust'] , config['geotop']['targV'] , "TRUE", "TRUE"]
				subprocess.check_output(cmd)

				logging.info( "TopoSUB INFORM complete"  )

				# sample dist plots
				src = "./rsrc/sampleDistributions.R"
				arg1 = home
				arg2 = config['toposcale']['svfCompute']
				arg3 = "sampDistInfm.pdf"
				cmd = "Rscript %s %s %s %s"%(src,arg1,arg2,arg3)
				os.system(cmd)

				logging.info( "Assign surface types")
				cmd = ["Rscript",  "./rsrc/modalSurface.R", home]
				subprocess.check_output(cmd)
				f = open(home + "/SUCCESS_TSUB_INFORM", "w")
			else:
				logging.info( "TopoSUB INFORM already run"  )


	#=========================   END of memeber 1 only section   ===============================================


	#===============================================================================
	#	Run toposcale 2
	#===============================================================================
	
	fname1 = home + "/landformsInform.pdf"
	if os.path.isfile(fname1) == False: #NOT ROBUST
		end = datetime.strptime(config['main']['endDate'], "%Y-%m-%d")

		# Redefine starttime in case sim is restarted
		startTime=(
		str('{0:04}'.format(start.year))+"-"
		+str('{0:02}'.format(start.month))+"-"
		+str('{0:02}'.format(start.day))+" "
		+str('{0:02}'.format(start.hour))+":"
		+str('{0:02}'.format(start.minute))+":"
		+str('{0:02}'.format(start.second))
		)

		# TReset to full length endtime
		endTime=(
		str('{0:04}'.format(end.year))+"-"
		+str('{0:02}'.format(end.month))+"-"
		+str('{0:02}'.format(end.day))+" "
		+str('{0:02}'.format(end.hour))+":"
		+str('{0:02}'.format(end.minute))+":"
		+str('{0:02}'.format(end.second))
		)


		if config["forcing"]["product"]=="ensemble_members":

			logging.info( "Run TopoSCALE 2 ensembles")

			cmd = [
			"python",  
			tscale_root+"/tscaleV2/toposcale/tscale_run_ensemble.py",
			wd + "/forcing/", 
			home,home+"/forcing/" ,
			str(member),
			startTime,
			endTime
			]

		if config["forcing"]["product"]=="reanalysis":

			logging.info( "Run TopoSCALE 1 reanalysis")

			cmd = [
			"python",  
			tscale_root+"/tscaleV2/toposcale/tscale_run.py",
			wd + "/forcing/", 
			home,home+"/forcing/",
			startTime,
			endTime
			]

		subprocess.check_output(cmd)
		f = open(home + "/SUCCESS_TSCALE2", "w")
	else:
		logging.info( "tscale2 already run")
	#===============================================================================
	#	Prepare inputs
	#===============================================================================
	logging.info( "Convert met to geotop")
	files = os.listdir(home+"/forcing/")

	for file in files:
		cmd = ["Rscript",  "./rsrc/met2geotop.R",home+"/forcing/"+file]
		subprocess.check_output(cmd)

	logging.info( "prepare cluster sim directories")
	cmd = ["Rscript",  "./rsrc/setupSim.R", home]
	subprocess.check_output(cmd)

	logging.info( "prepare geotop.inpts")
	cmd = ["Rscript",  "./rsrc/makeGeotopInputs.R", home , config["main"]["srcdir"]+ "/geotop/geotop.inpts" ,config["main"]["startDate"],config["main"]["endDate"] ]
	subprocess.check_output(cmd)


	#===============================================================================
	#	Simulate results
	#===============================================================================
	sims = glob.glob(home+"/c0*")

	for sim in sims:
		logging.info( "run geotop" + sim)
		cmd = ["./geotop/geotop1.226", sim]
		subprocess.check_output(cmd)

	logging.info("Simulation finished!")
	logging.info(" %f minutes for total run" % round((time.time()/60 - start_time/60),2) )


# calling main
if __name__ == '__main__':
	
	wd = sys.argv[1]
	simdir = sys.argv[2]
	member = sys.argv[3]
	main(wd, simdir, member)


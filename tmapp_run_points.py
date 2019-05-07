#!/usr/bin/env python

"""tmapp_run.py


Example:

	joel@joel-ThinkPad-T440p:~/src/tmapp2$ python tmapp_run_points.py /home/joel/sim/imis/ SNOWPACK


ARGS:
	wd:
	simdir:
	member=1 (HRES) or 1:n (EDA)
	model= SNOWPACK or GEOTOP
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
import pandas as pd
from configobj import ConfigObj
import re

def main(wd, model="SNOWPACK"):

#===============================================================================
#	Config setup
#===============================================================================
	#os.system("python writeConfig.py") # update config DONE IN run.sh file
	
	config = ConfigObj(wd+"/config.ini")

	tscale_root=config['main']['tscale_root'] # path to tscaleV2 directory

	# config start and end date
	start = datetime.strptime(config['main']['startDate'], "%Y-%m-%d")
	end = datetime.strptime(config['main']['endDate'], "%Y-%m-%d")
	windCor=config['toposcale']['windCor']
#===============================================================================
#	Log
#===============================================================================
	#logfile=wd+"/sim/"+ simdir+"/logfile"
	logfile=wd+"/logfile"
	if os.path.isfile(logfile) == True:
		os.remove(logfile)
	logging.basicConfig(level=logging.DEBUG, filename=logfile, filemode="a+",
	                        format="%(asctime)-15s %(levelname)-8s %(message)s")

#===============================================================================
#	Timer
#===============================================================================
	start_time = time.time()

#===============================================================================
#	make dirs
#===============================================================================
	home = wd#+"/sim/"+simdir
	if not os.path.exists(home + "/forcing"):
		os.makedirs(home + "/forcing")

	# make out path for results
	out = home+"/out/"
	if not os.path.exists(out):
		os.makedirs(out)

#===============================================================================
#	Init ensemble memebers from memeber =1
#===============================================================================
	'''copy 
	-listpoints

	'''

	# if int(member) > 1:
	# 	ngrid = simdir.split("m")[0]
	# 	master= wd + '/sim/' + ngrid + 'm1'
	# 	src=master +"/listpoints.txt" 
	# 	dst= home+"/listpoints.txt"
	# 	copyfile(src,dst)
	# 	src=master +"/landcoverZones.txt" 
	# 	dst= home+"/landcoverZones.txt"
	# 	copyfile(src,dst)
	# 	src=master +"/landform.tif" 
	# 	dst= home+"/landform.tif"
	# 	copyfile(src,dst)




	#if int(member) == 1:
#=========================  start of memeber 1 only section   ==================

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
#	Run compute listpoints
#===============================================================================
	fname = home + "/listpoints.txt"
	if os.path.isfile(fname) == False:

		logging.info( "Compute listpoints")
		cmd = ["Rscript",  "./rsrc/makeListpoints2.R",home,config['main']['pointsShp']]
		subprocess.check_output(cmd)
		f = open(home + "/SUCCESS_LISTPOINTS", "w")
	else:
		logging.info("Listpoints already made!")
#===============================================================================
#	Run toposcale
#===============================================================================



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



	'''check for complete forcing/meteo* files==nclust'''
	meteoCounter = len(glob.glob1(home+"/out/","*.csv"))
	lp = pd.read_csv(home + "/listpoints.txt")

	if meteoCounter != len(lp.name):
		""" run informed toposub on just one year data for efficiency"""


		# if config['main']['runmode']=='grid':
		# 	if config["forcing"]["product"]=="ensemble_members":

		# 		logging.info( "Run TopoSCALE 1 ensembles")

		# 		cmd = [
		# 		"python",  
		# 		tscale_root+"/tscaleV2/toposcale/tscale_run_EDA.py",
		# 		wd + "/forcing/", 
		# 		home,
		# 		home+"/forcing/" ,
		# 		str(member),
		# 		startTime,
		# 		endTime,
		# 		windCor
		# 		]

		# 	if config["forcing"]["product"]=="reanalysis":

		# 		logging.info( "Run TopoSCALE 1 reanalysis")

		if config['main']['runmode']=='points':

			if config["forcing"]["product"]=="reanalysis":

				# 2d
		 	# 	cmd = [
				# "python",  
		 	# 	tscale_root+"/tscaleV2/toposcale/tscale_run.py",
		 	# 	wd + "/forcing/", 
		 	# 	home,
		 	# 	home+"/out/",
				# config['main']['startDate'],
				# config['main']['endDate'],
				# windCor
				# ]



				# logging.info( "Run TopoSCALE points reanalysis")

				# #3d

				cmd = [
				"python",  
				tscale_root+"/tscaleV2/toposcale/tscale3D.py",
				wd , 
				config['main']['runmode'],
				config['main']['startDate'],
				config['main']['endDate'],
				"HRES",
				'1'

				]


		subprocess.check_output(cmd)

		


				# report sucess
		f = open(home + "/SUCCESS_TSCALE1", "w")
	else:
		logging.info( "Toposcale 1 already run "+ str(len(lp.name))+ " meteo files found" )

	# list of toposcale generated forcing files with full path
	files = glob.glob(home+"/out/*.csv")
	print(files)
#===============================================================================
#	Prepare GEOTOP meteo file
#===============================================================================
	if model=="GEOTOP":
		logging.info( "Convert met to geotop format...")
		# make geotop met files
		for file in files:
			file =os.path.basename(file) # remove path
			cmd = ["Rscript",  "./rsrc/met2geotop.R",home+"/out/"+file]
			subprocess.check_output(cmd)

#===============================================================================
#	Prepare SNOWPACK SMET INI and SNO - use direct confiobj inserts here
#===============================================================================
	if model=="SNOWPACK":
		logging.info( "Preparing snowpack inputs...")

		# parse listpoints to get metadata
		lp = pd.read_csv(home + "/listpoints.txt")

		# make smet ini here
		# configure any additional / resampling /  QC here
		for file in files:
			file =os.path.basename(file) # remove path
			logging.info( "Now running "+file)
			# parse the file name to get id, -1 to get py index
			res =os.path.basename(file).split('.')[0]
			id =int(os.path.basename(res).split('meteoc')[1]) -1 
			
			cmd = ["Rscript",  "./rsrc/sp_makeInputs.R",
			config["main"]["srcdir"]+"/snowpack/",
			home+'/out/',
			file, 
			config['main']['startDate'], 'dummy'] # test to see if overidden by below - NOW redundent??
			subprocess.check_output(cmd)

			# quick fix to ensure second meteopath correctly configured
			# todo: cover all ini settins like this
			
			fileini = home+'/out/'+os.path.basename(file).split('.')[0]+".ini"
			print(fileini)
			configini = ConfigObj(fileini)
			configini['Output']['METEOPATH']=home+'/out/'
			configini['Input']['POSITION1']="latlon " +str(lp.lat[id])+", "+str(lp.lon[id])+" " +str(lp.ele[id])
			configini['Input']['CSV_NAME']=lp.name[id]
			configini['Input']['CSV_AZI']=lp.asp[id]
			configini['Input']['CSV_SLOPE']=lp.slp[id]
			configini['Output']['EXPERIMENT']=lp.name[id]
			configini.write()

			# stip out any quotations that stop snowpack parser
			with open(fileini, "r") as sources:
			    lines = sources.readlines()
			with open(fileini, "w") as sources:
			    for line in lines:
			        sources.write(re.sub(r'"', '', line))

			filesno = home+'/out/'+os.path.basename(file).split('.')[0]+".sno"
			# replace date in sno file
			with open(filesno, "r") as sources:
			    lines = sources.readlines()
			with open(filesno, "w") as sources:
			    for line in lines:
			        sources.write(re.sub(r'1997-09-01T00:00', config['main']['startDate']+'T00:00', line))

		# run meteoio
		for file in files:
			fileini = os.path.basename(file).split('.')[0]+".ini"
			cmd = [config["main"]["srcdir"]+"snowpack/data_converter "+ 
			config['main']['startDate'] +
			" "+ config['main']['endDate']+ 
			" " +config['meteoio']['timestep']+" "+ 
			home+"/out/"+fileini]
			logging.info( cmd)
			subprocess.check_output(cmd, shell=True)
	# cleanup
	#meteotoremove = glob.glob("*.csv")
	#os.remove(meteotoremove)
	


#===============================================================================
#	Prepare GEOTOP sims 
#===============================================================================
	if model=="GEOTOP":
		''' check for geotop run complete files'''
		runCounter = 0
		foundsims = []
		for root, dirs, files in os.walk(home):
			for file in files:    
				if file.endswith('_SUCCESSFUL_RUN'):
					runCounter += 1
					foundsims.append(os.path.join(root,file))

		fsims = [i.split('/', 2)[1] for i in foundsims]

		fname1 = home + "/SUCCESS_SIM1"
		if os.path.isfile(fname1) == False: #NOT ROBUST


			# case of no sims and probably no setup done
			if runCounter ==0:

				logging.info( "prepare cluster sim directories")
				cmd = ["Rscript",  "./rsrc/setupSim.R", home]
				subprocess.check_output(cmd)

				logging.info( "Assign surface types")
				cmd = ["Rscript",  "./rsrc/modalSurface_points.R", home]
				subprocess.check_output(cmd)

				logging.info( "prepare geotop.inpts")
				cmd = [
				"Rscript", 
				 "./rsrc/makeGeotopInputs.R", 
				 home , 
				 config["main"]["srcdir"]+ "/geotop/geotop.inpts" ,
				 config["main"]["startDate"],
				 config["main"]["endDate"] 
				 ]
				subprocess.check_output(cmd)

				sims = glob.glob(home+"/c0*")

				for sim in sims:
					logging.info( "run geotop" + sim)
					cmd = ["./geotop/geotop1.226", sim]
					subprocess.check_output(cmd)

			# CASE OF incomplete sims to be restarted (prob interuppted by cluster runtime limit)
			if runCounter != len(lp.name) and runCounter >0:
				logging.info("only " + str(runCounter)+ " complete sims found, finishing now...")
				# all sims to run
				sims = glob.glob(home+"/c0*")
				sims = [i.split('/', 1)[1] for i in sims]
				# fsims = found complemete sims
				# list only files that dont exist
				sims2do = [x for x in sims if x not in fsims]
				

				for sim in sims2do:
					logging.info( "run geotop " + sim)
					cmd = ["./geotop/geotop1.226", sim]
					subprocess.check_output(cmd)

			f = open(home + "/SUCCESS_SIM1", "w")

		else:
			logging.info( "Geotop 1 already run "+str(runCounter)+ 
				" _SUCCESSFUL_RUN files found" )


#===============================================================================
#	Prepare Snowpack sims - need to add all restart stuff
#===============================================================================
	if model=="SNOWPACK":
		logging.info("Running SNOWPACK!")
		myinis = glob.glob(home+"/out/"+"*.ini")
		for myini in myinis:
			logging.info("Running SNOWPACK " + myini)
			cmd=["snowpack -c "+ myini +" -e "+ config['main']['endDate']]
			subprocess.check_output(cmd, shell=True)




#===============================================================================
#	Calling Main
#===============================================================================
if __name__ == '__main__':
	
	wd = sys.argv[1]
	#simdir = sys.argv[2]
	#member = sys.argv[3]
	model = sys.argv[2]
	main(wd, model)


# # plot points
#  files = list.files(".","surface.txt", recursive=T)
#  par(mfrow=c(4,3))
#  for (i in files){
#  dat = read.csv(i)
#  plot(dat$snow_depth.mm.)
#  }
 
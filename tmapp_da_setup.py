#!/usr/bin/env python
import os
import subprocess
import pandas as pd
import time
import sys
from configobj import ConfigObj
import logging
import glob

# tmapp_darun

def main(wd, home, ensembleN):

	config = ConfigObj(wd+"/config.ini")
	root = home+"/ensemble"
	#N = config['ensemble']['members']

	#	Logging
	logging.basicConfig(level=logging.DEBUG, filename=home +"/logfile", filemode="a+",format="%(asctime)-15s %(levelname)-8s %(message)s")


	# write copy of config for ensemble editing
	config.filename = root +"/ensemble_config.ini"
	config.write()
	config = ConfigObj(config.filename)
	
	# start ensemble runs

	# read in csv as pd data
	df = pd.read_csv(root+"/ensemble.csv")

	# Assimilation cycle loop start here

	i=ensembleN

	# Loop Timer
	start_time = time.time()

	pbias = df['pbias'][i]
	tbias = df['tbias'][i]
	lwbias = df['lwbias'][i]
	swbias = df['swbias'][i]


	config["main"]["wd"]  = root + "/ensemble" + str(i) + "/"
	config["da"]["pscale"] = pbias #factor to multiply precip by
	config["da"]["tscale"] = tbias #factor to add to temp
	config["da"]["swscale"] = swbias
	config["da"]["lwscale"] = lwbias

	config.write()

	logging.info("Config settings used")
	logging.info(config)

	# make new dierectory
	dst = config['main']['wd']
	cmd = "mkdir  %s"%(dst)
	os.system(cmd)

	# copy sim dirs only
	src = home+"/c0*"
	dst = config['main']['wd']
	cmd = "cp -r  %s %s"%(src,dst)
	os.system(cmd)

	sim_dirs = glob.glob(config["main"]["wd"]+"/c0*")
	logging.info("Perturburbing meteo files for Ensemble " + str(ensembleN))
	# loop through sim dirs
	for s in sim_dirs:			
		
		df = pd.read_csv( s +"/meteo0001.txt")
		

		if config["da"]["PPARS"] == "P":
			df['Prec'] = df['Prec'] * config['da']['pscale'] #multiplicative

		if config["da"]["PPARS"] == "PT":
			df['Prec'] = df['Prec'] * config['da']['pscale'] #multiplicative
			# convert to K
			taK = df['Tair'] + 273.15
			# peturb and back to celcius
			df['Tair'] = (taK*config['da']['tscale']) - 273.15
			logging.info(config['da']['pscale'])

		if config["da"]["PPARS"] == "PTS":
			df['Prec'] = df['Prec'] * config['da']['pscale'] #multiplicative
			df['SW'] = df['SW'] * config['da']['swscale']##multiplicative
			# convert to K
			taK = df['Tair'] + 273.15
			# peturb and back to celcius
			df['Tair'] = (taK*config['da']['tscale']) - 273.15

		if config["da"]["PPARS"] == "PTSL":
			df['Prec'] = df['Prec'] * config['da']['pscale'] #multiplicative
			df['LW'] = df['LW'] * config['da']['lwscale']##multiplicative
			df['SW'] = df['SW'] * config['da']['swscale']##multiplicative
			# convert to K
			taK = df['Tair'] + 273.15
			# peturb and back to celcius
			df['Tair'] = (taK*config['da']['tscale']) - 273.15		# scale meteo

		#MULTIPAR CROSS CORELATION": https://www.the-cryosphere.net/10/103/2016/tc-10-103-2016.pdf

		#write meteo
		df.to_csv( s +"/meteo0001.txt", index = False)

#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys
	wd      = sys.argv[1]
	home      = sys.argv[2]
	ensembleN =sys.argv[3]
	main(config)

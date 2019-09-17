#!/usr/bin/env python
""" 
This module scale meteo0001.txt files directly with ensemble perturbations. 
 

"""
import subprocess
import glob
import logging
import os
import pandas as pd

def main(Ngrid, config):

	#list sim dirs
	sim_dirs = glob.glob(Ngrid+"/c0*")

	logging.info("Perturburbing simulation meteo files" + Ngrid)
	# logging.info(sim_dirs)

	# loop through sim dirs
	for s in sim_dirs:			
		logging.info("Perturburbing simulation meteo files" + s)
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
	Ngrid      = sys.argv[1]
	config      = sys.argv[2]
	main(Ngrid, config)



	#config['geotop']['lsmPath']+'/'+config['geotop']['lsmExe']
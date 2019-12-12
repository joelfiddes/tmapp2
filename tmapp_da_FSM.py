#!/usr/bin/env python
import os
import subprocess
import pandas as pd
import time
import sys
from configobj import ConfigObj
import logging
import glob
from tqdm import tqdm


# tmapp_darun
# approx 38 s for 100 samples and 32 model types (320 sims) for 1 sim year
#

def main(wd, home, ensembleN):

	config = ConfigObj(wd+"/config.ini")
	root = home+"/ensemble"
	simdir = os.path.basename(home)
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


	# pad to 3 digits for sorting ease
	i=ensembleN
	ipad=	'%03d' % (int(ensembleN),)
	# Loop Timer
	start_time = time.time()

	pbias = df['pbias'][i]
	tbias = df['tbias'][i]
	lwbias = df['lwbias'][i]
	swbias = df['swbias'][i]


	config["main"]["wd"]  = root + "/ensemble" + str(ipad) + "/"
	config["da"]["pscale"] = pbias #factor to multiply precip by
	config["da"]["tscale"] = tbias #factor to add to temp
	config["da"]["swscale"] = swbias
	config["da"]["lwscale"] = lwbias

	config.write()

	logging.info("Config settings used")
	logging.info(config)

	# make new dierectory if does not exist
	dst = config['main']['wd']
	if not os.path.isdir(dst):
		cmd = "mkdir  %s"%(dst)
		os.system(cmd)

	# remove all files in case any outfiles exist
	# copy sim dirs only
	src = home+"/forcing/fsm*.txt"
	dst = config['main']['wd']
	cmd = "cp -r  %s %s"%(src,dst)
	os.system(cmd)


	tsfiles = glob.glob(dst + "/fsm*.txt")
	timestep = int(config["forcing"]["step"]) *60*60 # forcing in seconds 
	logging.info("Perturb and run ensemble...")
	tout=24/(timestep/60/60)

	
	for myfile in tqdm(tsfiles):
		myfile = os.path.basename(myfile)  # remove path
		# parse original meteo and purturb       
		
		df = pd.read_csv( config["main"]["wd"]+ myfile,sep='\t', header=None)
	

		# fixed columns table returned:
		#SW = col 5 (4)
		#LW = col 6 (5)
		#Sf = col 7 (6) 
		#Rf = col 8 (7)
		#TA = col 9 (6)
		# | Variable | Units  | Description       |
		# |----------|--------|-------------------|
		# | year     | years  | Year              |
		# | month    | months | Month of the year |
		# | day      | days   | Day of the month  |
		# | hour     | hours  | Hour of the day   |
		# | SW       | W m<sup>-2</sup> | Incoming shortwave radiation  |
		# | LW       | W m<sup>-2</sup> | Incoming longwave radiation   |
		# | Sf       | kg m<sup>-2</sup> s<sup>-1</sup> | Snowfall rate |
		# | Rf       | kg m<sup>-2</sup> s<sup>-1</sup> | Rainfall rate |
		# | Ta       | K      | Air temperature      |
		# | RH       | RH     | Relative humidity    |
		# | Ua       | m s<sup>-1</sup> | Wind speed |
		# | Ps       | Pa     | Surface air pressure |




		if config["da"]["PPARS"] == "P":
			df.iloc[:,6] = df.iloc[:,6] * config['da']['pscale'] #multiplicative formal
			df.iloc[:,7] = df.iloc[:,7] * config['da']['pscale'] #multiplicative

		if config["da"]["PPARS"] == "PT":
			df.iloc[:,6] = df.iloc[:,6] * config['da']['pscale'] #multiplicative
			df.iloc[:,7] = df.iloc[:,7] * config['da']['pscale'] #multiplicative
			df.iloc[:,8] = df.iloc[:,8]*config['da']['tscale']


		if config["da"]["PPARS"] == "PTS":

			df.iloc[:,6] = df.iloc[:,6] * config['da']['pscale'] #multiplicative
			df.iloc[:,7] = df.iloc[:,7] * config['da']['pscale'] #multiplicative
			df.iloc[:,8] = df.iloc[:,8]*config['da']['tscale']
			df.iloc[:,4] = df.iloc[:,4] * config['da']['swscale']##multiplicative


		if config["da"]["PPARS"] == "PTSL":
			df.iloc[:,6] = df.iloc[:,6] * config['da']['pscale'] #multiplicative
			df.iloc[:,7] = df.iloc[:,7] * config['da']['pscale'] #multiplicative
			df.iloc[:,8] = df.iloc[:,8]*config['da']['tscale']
			df.iloc[:,4] = df.iloc[:,4] * config['da']['swscale']##multiplicative
			df.iloc[:,5] = df.iloc[:,5] * config['da']['lwscale']##multiplicative

		df.to_csv( config["main"]["wd"]+myfile,sep='\t', index = False, header=False)
		

		for n in range(0,1):
			nconfig=str(n)
			nconfig2='%02d' % (n,)

			# get myfile id
			a  = myfile.split('.')[0]                                                                                                                
			fileID ='%03d' % (int(a.split('fsm')[1]), )
			
			# write namelist
			nlst = open(home+"/nlst_tmapp.txt","w") 

			str1="! namelists for running FSM "
			str2="\n&config"
			str18="\n  nconfig="+nconfig
			str3="\n/"
			str4="\n&drive"
			str5="\n  met_file = './sim/"+simdir+"/ensemble/ensemble"+str(ipad)+"/"+myfile+"'"
			str6="\n  zT = 1.5"
			str7="\n  zvar = .FALSE."
			str8="\n/"
			str9="\n&params"
			str10="\n/"
			str11="\n&initial"
			str12="\n  Tsoil = 282.98 284.17 284.70 284.70"
			str13="\n/"
			str14="\n&outputs"
			str15="\n  out_file = './sim/"+simdir+"/ensemble/ensemble"+str(ipad)+"/"+'out'+fileID+'_'+nconfig2+".txt'"
			str16="\n  Nave=" +str(tout)
			str17="\n/\n"

			L = [str1, str2, str18, str3, str4, str5, str6, str7, str8, str9, str10, str11,str12,str13,str14,str15,str16,str17] 
			nlst.writelines(L)
			nlst.close() 

			# run model
			os.chdir(wd)
			fsm="./FSM"
			cmd=fsm+ " < " +home+"/nlst_tmapp.txt"

			os.system(cmd)
			os.chdir(config['main']['srcdir'])

	# remove all forcing files
	os.system("rm " + config["main"]["wd"]+ "fsm*.txt")

#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys
	wd      = sys.argv[1]
	home      = sys.argv[2]
	ensembleN =sys.argv[3]
	main(config)

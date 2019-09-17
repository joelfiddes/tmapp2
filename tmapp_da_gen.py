#!/usr/bin/env python
import os
import subprocess
import pandas as pd
import time
import sys
from configobj import ConfigObj
import logging

# tmapp_dasetup

def main(wd, home):

	config = ConfigObj(wd+"/config.ini")
	#initgrids = config['main']['initGrid']
	root = home+"/ensemble"
	N = config['ensemble']['members']
	#initdir = config['main']['initDir']
	master = config['main']['wd'] # SIMDIR?


	# Creat wd dir if doesnt exist
	if not os.path.exists(root):
		os.makedirs(root)

	#	Logging
	logging.basicConfig(level=logging.DEBUG, filename=home +"/logfile", filemode="a+",format="%(asctime)-15s %(levelname)-8s %(message)s")


	# write copy of config for ensemble editing
	config.filename = root +"/ensemble_config.ini"
	config.write()
	config = ConfigObj(config.filename)
	

	# start ensemble runs
	logging.info("Generating ensemble distributions" )

	#generate ensemble
	subprocess.call(["Rscript", "rsrc/ensemGen.R" , str(N) , root])

	


#====================================================================
#	Calling MAIN
#====================================================================
if __name__ == '__main__':
	import sys
	wd      = sys.argv[1]
	home      = sys.argv[2]
	main(config)


# 

"""
python2

This is a linear process requiring single processor 

Example:


Vars:


Details:


"""

# args
import sys
import os
wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
sys.path.append(os.getcwd())
print (sys.version)

from configobj import ConfigObj
config = ConfigObj(wd + "/config.ini")
tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory
sys.path.insert(1, tscale_root)

import glob
import tscale_lib as tlib






# config
config = ConfigObj(wd + "/config.ini")
demRes = config["main"]["demRes"] 
demDir=config["main"]["demdir"]
pointsShp = config['main']['pointsShp']
pointsBuffer = 0.08


# =========================================================================
#	Log
# =========================================================================




tlib.download_sparse_dem(wd, pointsShp, demRes, pointsBuffer, demDir)
tlib.setup_sim_dirs(wd)

# make outdir
outdir = wd+"/out/"
if not os.path.exists(outdir):
	os.makedirs(outdir)
	
logging.info("Setup complete!")
print("Setup complete!")
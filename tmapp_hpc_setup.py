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
import logging





# config
config = ConfigObj(wd + "/config.ini")
demRes = config["main"]["demRes"] 
demDir=config["main"]["demdir"]
forcing_grid =config["forcing"]["grid"]
latN = config["main"]["latN"]
latS = config["main"]["latS"]
lonE = config["main"]["lonE"]
lonW = config["main"]["lonW"]


# =========================================================================
#	Log
# =========================================================================
logfile = wd+ "/logfile_setup"
if os.path.isfile(logfile) == True:
	os.remove(logfile)


# to clear logger: https://stackoverflow.com/questions/30861524/logging-basicconfig-not-creating-log-file-when-i-run-in-pycharm
for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

logging.basicConfig(level=logging.DEBUG, filename=logfile,filemode="a+",format="%(asctime)-15s %(levelname)-8s %(message)s")

jobid = os.getenv('SLURM_ARRAY_TASK_ID')
logging.info("Running setup on jobid"+ str(jobid))


# make wd dirs
tlib.make_dirs(wd)

# Compute time step or era5 forcing
files = sorted(glob.glob(wd + "/forcing/SURF*.nc"))  
stephr = tlib.compute_timestep(files[0])

# make shape
tlib.make_poly(latN,latS,lonE,lonW,wd)

# get DEM
shp = wd +"/spatial/domain.shp"
tlib.download_dem(wd, demDir,shp, demRes)

# make terrain (need check here)
tlib.compute_terrain_ndvi( wd )

# make sim dirs and cookie cut ele,slf,asp,ndvi to them
tlib.setup_sim_dirs_grid(wd, forcing_grid)


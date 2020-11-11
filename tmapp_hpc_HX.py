# run python tmapp_hpc_perturb.py #WD
import subprocess
import sys
import os
from configobj import ConfigObj
import glob

wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
config = ConfigObj(wd + "/config.ini")

# ===============================================================================
#	Make ensemble.csv (peturb pars)
# ===============================================================================

ensemb_dir = wd+"/ensemble"
N = config['ensemble']['members']

# original construction of ensemRes object does not scale (sample*ensembles*time)

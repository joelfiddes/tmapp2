import sys
wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
grid= int(sys.argv[2]) 

import os
jobid = os.getenv('SLURM_ARRAY_TASK_ID')

import glob
from configobj import ConfigObj
config = ConfigObj(wd + "/config.ini")
svfSectors = config['toposcale']['svfSectors']
svfMaxDist = config['toposcale']['svfMaxDist']
tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory
nclust = config['toposub']['nclust']
tmapp_root=config['main']['srcdir'] 
sys.path.insert(1, tscale_root)
import tscale_lib as tlib


print("Computing SVF grid " + str(grid))


homes = sorted(glob.glob(wd+"/sim/*"))
tlib.compute_svf(homes[grid], svfSectors, svfMaxDist)
tlib.compute_surface(homes[grid] )
tlib.toposub(tmapp_root, homes[grid], nclust)
print("Grid " + str(jobid) + " done!")
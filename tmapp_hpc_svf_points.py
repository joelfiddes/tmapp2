import sys
wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
starti= int(sys.argv[2]) 
endi= int(sys.argv[3]) 

import os
jobid = os.getenv('SLURM_ARRAY_TASK_ID')

import glob
from configobj import ConfigObj
config = ConfigObj(wd + "/config.ini")
svfSectors = config['toposcale']['svfSectors']
svfMaxDist = config['toposcale']['svfMaxDist']
tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory


sys.path.insert(1, tscale_root)
import tscale_lib as tlib


print("Computing SVF grid " + str(grid))


homes = sorted(glob.glob(wd+"/sim/*")) # order doesnt matter
tasks = homes[int(starti)-1:int(endi)]

for i,task in enumerate(tasks):
	tlib.compute_terrain( task, str(svfSectors), str(svfMaxDist) )   
	tlib.make_listpoints(task, pointsShp)
	print("Grid " + str(task) + " done!")

	





# running tscale
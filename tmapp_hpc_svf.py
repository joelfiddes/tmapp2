import sys
import os
import glob

wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
grid= sys.argv[2] 
jobid = os.getenv('SLURM_ARRAY_TASK_ID')

print("Computing SVF grid " + str(jobid))
config = ConfigObj(wd + "/config.ini")
svfSectors = config['toposcale']['svfSectors']
svfMaxDist = config['toposcale']['svfMaxDist']

homes = sorted(glob.glob(wd+"/sim/*"))
tlib.compute_svf(homes[grid], svfSectors, svfMaxDist)
print("Grid " + str(jobid) + " done!")
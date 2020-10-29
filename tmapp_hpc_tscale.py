import sys
wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
starti= sys.argv[2] 
endi= sys.argv[3] 

import glob
import os
jobid = os.getenv('SLURM_ARRAY_TASK_ID')

from configobj import ConfigObj
config = ConfigObj(wd + "/config.ini")
tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory
sys.path.insert(1, tscale_root)
import tscale3D



mylist = glob.glob(wd+'/forcing/SURF_*')
mymonths =sorted([i.split('SURF_', 1)[1] for i in mylist])

# if submitted end of array is long than number of months then set to length of months
if int(endi) > len(mymonths):
	(endi) = len(mymonths)

# compute month range to compute by this worker (python index conversion)
start = mymonths[int(starti) -1].split(".nc")[0]
end  = mymonths[int(endi) -1].split(".nc")[0]  

print("Jobid "+ str(jobid)+ " toposcaling "+ str(start)+ " to " + str(end))
tscale3D.main(wd, start, end) 
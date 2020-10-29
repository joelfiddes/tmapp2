import pandas as pd
import logging
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
import tscale_lib as tlib

# pars to add to config
reduceSteepSnow='TRUE'
outputFormat='FSM'


#	Log
logdir = wd+"/logs/"
if not os.path.exists(logdir):
	os.makedirs(logdir)

logfile = logdir+ "/logfile_tscale"+ jobid
if os.path.isfile(logfile) == True:
	os.remove(logfile)


# to clear logger: https://stackoverflow.com/questions/30861524/logging-basicconfig-not-creating-log-file-when-i-run-in-pycharm
for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

logging.basicConfig(level=logging.DEBUG, filename=logfile,filemode="a+",format="%(asctime)-15s %(levelname)-8s %(message)s")





# make outdir
outdir = wd+"/out/"
if not os.path.exists(outdir):
	os.makedirs(outdir)

# concat all listpoint files
filenames = sorted(glob.glob(wd + "/*/*/listpoints.txt"))

dfs = []
for filename in filenames:
	dfs.append(pd.read_csv(filename))

# Concatenate all lp data into one DataFrame
lp = pd.concat(dfs, ignore_index=True)
lp.to_csv(path_or_buf=wd+"/listpoints.txt" ,na_rep=-999,float_format='%.3f')


mylist = glob.glob(wd+'/forcing/SURF_*')
mymonths =sorted([i.split('SURF_', 1)[1] for i in mylist])

# if submitted end of array is long than number of months then set to length of months
if int(endi) > len(mymonths):
	(endi) = len(mymonths)

# compute month range to compute by this worker (python index conversion)
start = mymonths[int(starti) -1].split(".nc")[0]
end  = mymonths[int(endi) -1].split(".nc")[0]  


logging.info("Jobid "+ str(jobid)+ " toposcaling "+ str(start)+ " to " + str(end))

tasks = mymonths[int(starti)-1:int(endi)]

for i,task in enumerate(tasks):

	logging.info("toposcaling "+ tasks[i])
	print(("toposcaling "+ tasks[i]))
	tlib.tscale3dmain(wd,tasks[i],lp, reduceSteepSnow, outputFormat)






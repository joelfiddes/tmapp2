import pandas as pd
import sys
import os
import glob
import logging
wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
starti= sys.argv[2]
endi= sys.argv[3]

from configobj import ConfigObj
config = ConfigObj(wd + "/config.ini")
tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory
sys.path.insert(1, tscale_root)
import tscale_lib as tlib

namelist="/home/caduff/src/FSM/nlst_tmapp.txt"
fsmexepath = "/home/caduff/src/FSM/FSM"
outputFormat='FSM'



#	Log
logdir = wd+"/logs/"
if not os.path.exists(logdir):
	os.makedirs(logdir)

logfile = logdir+ "/logfile_sim"+ jobid
if os.path.isfile(logfile) == True:
	os.remove(logfile)


# to clear logger: https://stackoverflow.com/questions/30861524/logging-basicconfig-not-creating-log-file-when-i-run-in-pycharm
for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

logging.basicConfig(level=logging.DEBUG, filename=logfile,filemode="a+",format="%(asctime)-15s %(levelname)-8s %(message)s")







# outputFormat='FSM'
lp = pd.read_csv(wd+"/listpoints.txt")

# if submitted end of array is long than number of months then set to length of months
if int(endi) > len(mymonths):
	endi = len(lp.id)

ids=range(len(lp.id))
tasks = ids[int(starti)-1:int(endi)]

for i,task in enumerate(tasks):
	print("concat "+ str(tasks[i]) )
	tlib.concat_results(wd,str(tasks[i]+1), outputFormat)



meteofiles = sorted(glob.glob(wd+"/out/tscale*.csv"))
tasks = meteofiles[int(starti)-1:int(endi)]

for i,task in enumerate(tasks):
	print("Running FSM "+ tasks[i])
	logging.info("Running FSM "+ tasks[i])
	tlib.fsm_sim(tasks[i],namelist,fsmexepath)
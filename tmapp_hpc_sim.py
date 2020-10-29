
import sys
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







# outputFormat='FSM'
lp = pd.read_csv(wd+"/listpoints.txt")

ids=range(len(lp.id))
tasks = ids[int(starti)-1:int(endi)]

for i,task in enumerate(task):
	print("concat "+ str(tasks[i]) )
	tlib.concat_results(wd,str(tasks[i]+1), outputFormat)



meteofiles = sorted(glob.glob(wd+"/out/tscale*.csv"))
tasks = meteofiles[int(starti)-1:int(endi)]

for i,task in enumerate(task):
	print("Running FSM "+ tasks[i])
	logging.info("Running FSM "+ tasks[i])
	tlib.fsm_sim(tasks[i],namelist,fsmexepath)
import pandas as pd
import sys
import os
import glob
import logging
wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
starti= sys.argv[2]
endi= sys.argv[3]
concat="FALSE"

# ensure we have a whole number, rounds up
starti = round(int(starti))
endi = round(int(endi))

from configobj import ConfigObj
config = ConfigObj(wd + "/config.ini")
tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory
sys.path.insert(1, tscale_root)
import tscale_lib as tlib

namelist="/home/caduff/src/FSM/nlst_tmapp.txt"
fsmexepath = "/home/caduff/src/FSM/FSM"
outputFormat='FSM'

jobid = os.getenv('SLURM_ARRAY_TASK_ID')

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

logging.info("Computing "+ str(starti) +" to "+str(endi) )





# outputFormat='FSM'
lp = pd.read_csv(wd+"/listpoints.txt")

# if submitted end of array is long than number of months then set to length of months
if int(endi) > len(lp.id):
	endi = len(lp.id)

ids=range(len(lp.id))
tasks = ids[int(starti)-1:int(endi)]

if concat=="TRUE":
	for i,task in enumerate(tasks):
		print("concat "+ str(tasks[i]+1) )
		logging.info("concat "+ str(tasks[i]+1) )
		tlib.concat_results(wd,str(tasks[i]+1), outputFormat)



#meteofiles = sorted(glob.glob(wd+"/out/tscale*.csv"))
#tasks = meteofiles[int(starti)-1:int(endi)]

def resamp_1H(path_inpt, freq='1H'):# create 1h wfj era5 obs data by

	# freq = '1H' or '1D'
	dfin =pd.read_csv(path_inpt, delim_whitespace=True, 
	header=None, index_col='datetime', 
                 parse_dates={'datetime': [0,1,2,3]}, 
                 date_parser=lambda x: pd.datetime.strptime(x, '%Y %m %d %H') )


	df = dfin.resample(freq).interpolate()


	dates=df.index
	df_fsm= pd.DataFrame({	
	 				"year": dates.year, 
	 				"month": dates.month, 
					"day": dates.day, 
					"hour": dates.hour,
					"ISWR":df.iloc[:,0]  , 
					"ILWR":df.iloc[:,1]  , 
					"Sf":df.iloc[:,2]  , # prate in mm/hr to kgm2/s
					"Rf":df.iloc[:,3]  , # prate in mm/hr to kgm2/s
					"TA":df.iloc[:,4]  , 
					"RH":df.iloc[:,5]  ,#*0.01, #meteoio 0-1
					"VW":df.iloc[:,6]  ,
					"P":df.iloc[:,7]  ,
					
					
					})

	df_fsm.to_csv(path_or_buf=path_inpt.split('.')[0]  + '_'+freq+'.csv' ,na_rep=-999,float_format='%.8f', header=False, sep='\t', index=False, 
		columns=['year','month','day', 'hour', 'ISWR', 'ILWR', 'Sf', 'Rf', 'TA', 'RH', 'VW', 'P'])

	return(path_inpt.split('.')[0]  + '_'+freq+'.csv')


for i,task in enumerate(tasks):
	meteofile = wd+"/out/tscale_"+str(task+1)+".csv"
	
	path = resamp_1H(meteofile)

	print("Running FSM "+ str(task+1))
	logging.info("Running FSM "+ str(task+1))
	tlib.fsm_sim(path,namelist,fsmexepath)
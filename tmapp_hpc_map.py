import sys
import os
import glob
import subprocess
import pandas as pd
from tqdm import tqdm
from configobj import ConfigObj

wd= sys.argv[1]
mode=sys.argv[2]

# contingent args on mode
if mode== 'subperiod':
	start= sys.argv[3]
	end= sys.argv[4]

#start='2003-05-01' 
#end = '2003-05-30'

# mode:
# 	subperiod
# 	allperiod
# 	da
# 	timseries

rcode = "/home/caduff/src/topoCLIM/spatialize.R"
col=2

def timeseries_means(wd, nsims, col):

	mean_ts=[]
	for ID in tqdm(range(nsims)):


		f=glob.glob(wd + "/fsm_sims/fsm_tscale_"+str(ID+1)+"_*")
		df =pd.read_csv(f[0], delim_whitespace=True, parse_dates=[[0,1,2]], header=None)
		df.set_index(df.iloc[:,0], inplace=True)  
		df.drop(df.columns[[0]], axis=1, inplace=True )  
		swe=df.iloc[:,col]
		swemean = swe.mean()
		mean_ts.append(swemean)


	pd.Series(mean_ts).to_csv(wd+"/mean_ts_"+str(col)+".csv",header=False, float_format='%.3f') 



def timeseries_means_period(wd, nsims, col, start, end):
	"""
	Date format "yyyy-mm-dd"
	if statrt and end are same date then  single day is computed
	"""


	mean_ts=[]
	for ID in tqdm(range(nsims)):


		f=glob.glob(wd + "/fsm_sims/fsm_tscale_"+str(ID+1)+"_*")
		df =pd.read_csv(f[0], delim_whitespace=True, parse_dates=[[0,1,2]], header=None)
		df.set_index(df.iloc[:,0], inplace=True)  
		df.drop(df.columns[[0]], axis=1, inplace=True )  
		swe=df.iloc[:,col]
		swemean = swe[slice(start,end)].mean()
		mean_ts.append(swemean)


	pd.Series(mean_ts).to_csv(wd+"/mean_ts_"+str(col)+"_"+start+end+".csv",header=False, float_format='%.3f') 

def timeseries_means_period_ensemble(wd, ensembleN, nsims, col, start, end):
	"""
	Date format "yyyy-mm-dd"
	if statrt and end are same date then  single day is computed
	"""

	i=int(ensembleN)
	ipad=	'%03d' % (i,)


	mean_ts=[]
	for ID in tqdm(range(nsims)):

		idpad =	'%03d' % (ID+1,)
		f=glob.glob(wd + "/ensemble/ensemble"+str(ipad)+"/out"+str(idpad)+"_*")
		df =pd.read_csv(f[0], delim_whitespace=True, parse_dates=[[0,1,2]], header=None)
		df.set_index(df.iloc[:,0], inplace=True)  
		df.drop(df.columns[[0]], axis=1, inplace=True )  
		swe=df.iloc[:,col]
		swemean = swe[slice(start,end)].astype(float).mean() # catches case where data has been return as object
		mean_ts.append(swemean)


	pd.Series(mean_ts).to_csv(wd+"/ensemble/ensemble"+str(ipad)+"/mean_ts_"+str(col)+"_"+start+end+".csv",header=False, float_format='%.3f') 

def timeseries(wd, nsims, col):
	'''compute daily time series of domain'''
	#gridseq =1,10,11,12,13,14,15,16,17,18,19,2,20,21,3,4,5,6,7,8,9

	mydf = pd.DataFrame()
	#mean_sample=[]
	for ID in tqdm(range(nsims)):

		
		f=glob.glob(wd + "/fsm_sims/fsm_tscale_"+str(ID+1)+"_*")
		df =pd.read_csv(f[0], delim_whitespace=True, parse_dates=[[0,1,2]], header=None)

		#df.set_index(df.iloc[:,0], inplace=True)  
		#df.drop(df.columns[[0]], axis=1, inplace=True )  
		swe=df.iloc[:,col+1]
		mydf[ID] = swe
		#mean_sample.append(swe.mean()) # use this to remove glacier samples

	return(mydf)
	pd.Series(mydf).to_csv(wd+"/mean_ts_"+str(col)+"_"+"TIMESERIES.csv",header=False, float_format='%.3f') 



config = ConfigObj(wd + "/config.ini")
nclust = config['toposub']['nclust']
nsims=len(glob.glob(wd+"/fsm_sims/fsm_tscale*"))

# clean up old resamples
for f in glob.glob(wd+"/out/"+ "*1D.csv"):
	os.remove(f)

# clean up old resamples
for f in glob.glob(wd+"/out/"+ "*1H.csv"):
	os.remove(f)


# compile timeseries means HIST
if mode=='allperiod':
	meanVar= wd+"/mean_ts_"+str(col)+".csv"
	outname="spatial_"+str(col)

	timeseries_means(wd, nsims, col)
	cmd = ["Rscript" ,rcode ,wd ,meanVar, str(nclust), outname]
	subprocess.check_output(cmd)

if mode=='subperiod':

	meanVar= wd+"/mean_ts_"+str(col)+"_"+start+end+".csv"
	outname="spatial_" +start+"_"+end+"_"+str(col)

	timeseries_means_period(wd, nsims, col, start, end)
	cmd = ["Rscript" ,rcode ,wd ,meanVar, str(nclust), outname]
	subprocess.check_output(cmd)

if mode=='da':
	# plot MAP ensemble
	w = pd.read_csv(wd+"/ensemble/weights.txt", header=None)
	ensembleN=w.idxmax()[1]  
	i=int(ensembleN+1)
	ipad=	'%03d' % (i,)

	timeseries_means_period_ensemble(wd,i,  nsims, col, start, end)

	meanVar= wd+"/ensemble/ensemble"+ipad+"/mean_ts_"+str(col)+"_"+start+end+".csv"
	outname="spatial_" +start+"_"+end+"_"+str(col)+"ensemble"+ipad
	cmd = ["Rscript" ,rcode ,wd ,meanVar, str(nclust), outname]
	subprocess.check_output(cmd)



#=== compare domain mean to obs open and DA

#=== compare domain mean to obs
if mode=='timeseries':
	meanVals = timeseries(wd, nsims, col)

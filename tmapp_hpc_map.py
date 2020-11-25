import sys
import os
import glob
import subprocess
import pandas as pd
from configobj import ConfigObj

wd= sys.argv[1]
mode=sys.argv[2]
ngrid = str(sys.argv[3])

# contingent args on mode
if mode== 'subperiod':
	start= sys.argv[4]
	end= sys.argv[5]

if mode== 'ensemble':
	start= sys.argv[4]
	end= sys.argv[5]

print("Mode = " + mode)
#start='2003-05-01' 
#end = '2003-05-30'

# mode:
# 	subperiod
# 	allperiod
# 	ensemble
# 	timseries

rcode = "/home/caduff/src/tmapp2/rsrc/spatialize.R"
col=2

def timeseries_means(wd, nsims, col):

	mean_ts=[]
	for ID in (range(nsims)):


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
	for ID in (range(nsims)):


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
	for ID in (range(nsims)):

		idpad =	'%03d' % (ID+1,)
		f=glob.glob(wd + "/ensemble/ensemble"+str(ipad)+"/out"+str(idpad)+"_*")
		df =pd.read_csv(f[0], delim_whitespace=True, parse_dates=[[0,1,2]], header=None)
		df.set_index(df.iloc[:,0], inplace=True)  
		df.drop(df.columns[[0]], axis=1, inplace=True )  
		swe=df.iloc[:,col]
		swemean = swe[slice(start,end)].astype(float).mean() # catches case where data has been return as object
		mean_ts.append(swemean)


	pd.Series(mean_ts).to_csv(wd+"/ensemble/ensemble"+str(ipad)+"/mean_ts_"+str(col)+"_"+start+end+".csv",header=False, float_format='%.3f') 


def timeseries_means_period_ensemble_MAP1(wd, ensembleN, nsims, col, start, end):
	"""
	Date format "yyyy-mm-dd"
	if statrt and end are same date then  single day is computed
	"""

	i=int(ensembleN)
	ipad=	'%03d' % (i,)


	mean_ts=[]
	for ID in (range(nsims)):

		idpad =	'%03d' % (ID+1,)
		f=glob.glob(wd + "/ensemble/ensemble"+str(ipad)+"/out"+str(idpad)+"_*")
		df =pd.read_csv(f[0], delim_whitespace=True, parse_dates=[[0,1,2]], header=None)
		df.set_index(df.iloc[:,0], inplace=True)  
		df.drop(df.columns[[0]], axis=1, inplace=True )  
		swe=df.iloc[:,col]
		swemean = swe[slice(start,end)].astype(float).mean() # catches case where data has been return as object
		mean_ts.append(swemean)


	return(mean_ts) # mean value for ensemble

def timeseries_means_period_ensemble_MAP2(wd, NENS, nsims, col, start, end):
	
	ens_ts=[]
	for i in range(NENS):
		ensembleN = i+1
		print(ensembleN)
		a= 	timeseries_means_period_ensemble_MAP1(wd, ensembleN, nsims, col, start, end)
		ens_ts.append(a)

	return(ens_ts)



def timeseries(wd, nsims, col):
	'''compute daily time series of domain'''
	#gridseq =1,10,11,12,13,14,15,16,17,18,19,2,20,21,3,4,5,6,7,8,9

	mydf = pd.DataFrame()
	#mean_sample=[]
	for ID in (range(nsims)):

		
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
	cmd = ["Rscript" ,rcode ,wd ,meanVar, str(nclust), outname, ngrid]
	subprocess.check_output(cmd)

if mode=='subperiod':

	meanVar= wd+"/mean_ts_"+str(col)+"_"+start+end+".csv"
	outname="spatial_" +start+"_"+end+"_"+str(col)

	timeseries_means_period(wd, nsims, col, start, end)
	cmd = ["Rscript" ,rcode ,wd ,meanVar, str(nclust), outname, ngrid]
	subprocess.check_output(cmd)

if mode=='ensemble':
	# plot MAP ensemble
	w = pd.read_csv(wd+"/ensemble/weights.txt", header=None)
	ensembleN=int(w.idxmax()  +1)

	ipad=	'%03d' % (ensembleN,)

	timeseries_means_period_ensemble(wd,ensembleN,  nsims, col, start, end)

	meanVar= wd+"/ensemble/ensemble"+ipad+"/mean_ts_"+str(col)+"_"+start+end+".csv"
	outname="spatial_" +start+"_"+end+"_"+str(col)+"ensemble"+ipad
	cmd = ["Rscript" ,rcode ,wd ,meanVar, str(nclust), outname, str(ngrid)]
	subprocess.check_output(cmd)






#=== compare domain mean to obs open and DA

#=== compare domain mean to obs
if mode=='timeseries':
	meanVals = timeseries(wd, nsims, col)


if mode == 'map':
	# find all ensemble result files
	ensembleResults =glob.glob(wd + "/ensembRes*")
	lp = pd.read_csv(wd + "/listpoints.txt")
	w = np.array(pd.read_csv(wd+"/ensemble/weights.txt", header=None))

	import re                                                                                                                                                                                                                                                             

	def natural_sort(l): 
		convert = lambda text: int(text) if text.isdigit() else text.lower() 
		alphanum_key = lambda key: [ convert(c) for c in re.split('([0-9]+)', key) ] 
		return sorted(l, key = alphanum_key)

	ensembleResults_sort = natural_sort(ensembleResults)



	# loop over to do processing
	data=[]
	for eres in ensembleResults_sort:
		ensembRes2 = pd.read_csv(eres, header=None) # shape should be N_sample (grid*Nclust) x N_obs
		data.append(ensembRes2)

	a =np.dstack(data) # sample x time * ensembles
	a2 = 	a*w.transpose() # times by pbs weights
	a3 =a2.sum(2) # sum the weighted values
	a4= a3.mean(1) # mean through time

	pd.Series(a4).to_csv(wd+"/PBSMAP_ts_"+str(col)+".csv",header=False, float_format='%.3f') 
	meanVar= wd+"/PBSMAP_ts_"+str(col)+".csv"

	outname="PBSMAP_ts_"+str(col)
	cmd = ["Rscript" ,rcode ,wd ,meanVar, str(nclust), outname, str(ngrid)]
	subprocess.check_output(cmd)

	# 	Vect = lp.members
	# 	arr = ensembRes2.transpose()*Vect
	# 	HXi = arr.sum(axis=1)/sum(lp.members)
	# 	data.append(HXi)

	# HX = np.array(data).transpose() 




	ens_mean = timeseries_means_period_ensemble_MAP2(wd, NENS, nsims, col, start, end)
	x =np.asarray(ens_mean)
	w = pd.read_csv(wd+"/ensemble/weights.txt", header=None)
	y =np.array(w)*x
	ensembleMean = y.mean(1)

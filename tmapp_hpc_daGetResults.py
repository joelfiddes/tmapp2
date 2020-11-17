import sys
import os
import glob
import numpy as np
import pandas as pd


wd= sys.argv[1]
da_year = sys.argv[2]
ensembleN =sys.argv[3]

# ===============================================================================
#	Make results arrays of SWE (Dims = time*samples) per ensemble
# ===============================================================================

print("Generate results array ensemble "+ str(ensembleN))
ipad=   '%03d' % (int(ensembleN),)
successFile = wd + "/ensemble/ensemble" + str(ipad) + "/_RUN_SUCCESS"
a =glob.glob(wd + "/ensemble/ensemble" + str(ipad) +"/out*")

# finishedsims = [os.path.split(i)[0] for i in a]
# myfiles = [glob.glob(i+"/out*") for i in finishedsims]
# flat_list = [item for sublist in myfiles for item in sublist]
# file_list = sorted(flat_list)  


#Natural sort to get correct order ensemb * samples
import re                                                                                                                                                                                                                                                             

def natural_sort(l): 
	convert = lambda text: int(text) if text.isdigit() else text.lower() 
	alphanum_key = lambda key: [ convert(c) for c in re.split('([0-9]+)', key) ] 
	return sorted(l, key = alphanum_key)

file_list = natural_sort(a)

# compute dates index for da we always extract 31 March to Jun 30 for DA - this may of course not always be appropriate
df =pd.read_csv(file_list[0], delim_whitespace=True, parse_dates=[[0,1,2]], header=None)
startIndex = df[df.iloc[:,0]==str(da_year)+"-01-31"].index.values     
endIndex = df[df.iloc[:,0]==str(da_year)+"-06-19"].index.values     

if len(startIndex) ==0:
	sys.exit("da_year does not exist in simulation period")
if len(endIndex) ==0:
	sys.exit( "da_year does not exist in simulation period")

data = []
for file_path in file_list:
	data.append( np.genfromtxt(file_path, usecols=6)[int(startIndex):int(endIndex)]   )

myarray = np.asarray(data)
df =pd.DataFrame(myarray)

df.to_csv( wd+'/ensembRes'+str(ipad)+'.csv', index = False, header=False)


# get open - loop results, but only once when ensembleN=0
if int(ensembleN)==1:

	a =glob.glob(wd + "/fsm_sims/*")
	file_listOL = natural_sort(a)

	df =pd.read_csv(file_listOL[0], delim_whitespace=True, parse_dates=[[0,1,2]], header=None)
	startIndex = df[df.iloc[:,0]==str(da_year)+"-01-31"].index.values     
	endIndex = df[df.iloc[:,0]==str(da_year)+"-06-19"].index.values   


	data = []
	for file_path in file_listOL:
		data.append( np.genfromtxt(file_path, usecols=6)[int(startIndex):int(endIndex)]   )

	myarray = np.asarray(data)
	df =pd.DataFrame(myarray)

	# 2d rep of 3d ensemble in batches where ensemble changes slowest
	df.to_csv( wd+'/openloopRes.csv', index = False, header=False)

                



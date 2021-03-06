# run as single job 
# python tmapp_hpc_HX.py wd da_year
from configobj import ConfigObj
import glob
import pandas as pd
import numpy as np
import subprocess
import sys

wd= sys.argv[1] # wd ='/home/caduff/sim//ch_tmapp_50/' 
da_year=sys.argv[2] # da_year=2003
config = ConfigObj(wd + "/config.ini")

#constants
sdThresh=5
R=0.016
#R=0.0001
# ===============================================================================
#	Kode
# ===============================================================================
fsca= pd.read_csv(wd + "/meanSCA.csv")
fsca_dates= pd.read_csv(wd + "/fsca_dates.csv")
ensemb_dir = wd+"/ensemble"
N = config['ensemble']['members']

lp = pd.read_csv(wd + "/listpoints.txt")

# find all ensemble result files
ensembleResults =glob.glob(wd + "/ensembRes*")

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
	ensembRes2[ ensembRes2 <= sdThresh ] = 0
	ensembRes2[ ensembRes2 > sdThresh ] = 1
	Vect = lp.members
	arr = ensembRes2.transpose()*Vect
	HXi = arr.sum(axis=1)/sum(lp.members)
	data.append(HXi)

HX = np.array(data).transpose() # result is 2dims N_obs * N_ensemble if not an ensemblerun has failed
if len(HX.shape) <2:
	print "HX failed, an Ensemble run must have failed"
# make the real value matrix fro plotting
data=[]
for eres in ensembleResults_sort:
	ensembRes2 = pd.read_csv(eres, header=None)
	ensembRes2[ensembRes2>1000]=1000
	Vect = lp.members
	arr = ensembRes2.transpose()*Vect
	HXi = arr.sum(axis=1)/sum(lp.members)
	data.append(HXi)

HX_swe = np.asarray(data).transpose()

# open loop 
openloop =wd + "/openloopRes.csv"
ensembRes2 = pd.read_csv(openloop, header=None)
ensembRes2[ensembRes2>1000]=1000
Vect = lp.members
arr = ensembRes2.transpose()*Vect
oloop = arr.sum(axis=1)/sum(lp.members)



# cut all values > 10000
# extract obs for da year
startIndex = fsca_dates[fsca_dates.iloc[:,0]==str(da_year)+"-01-31"].index.values     
endIndex = fsca_dates[fsca_dates.iloc[:,0]==str(da_year)+"-06-19"].index.values 
Y=fsca[int(startIndex):int(endIndex)]
Y = Y.mean_fsca/100 
print(startIndex)
print(endIndex)

# particle batch smoothert

No=len(Y)
Rinv=np.array([(1/R)]*No)
mat = np.ones((1,HX.shape[1])) 

# reshape Y to have dims of mat
Y1 = np.reshape(np.array(Y), (80, 1)) 

# Calculate the likelihood.
Inn= np.kron(mat,Y1 )-HX

# with %*% gives NA
EObj=Rinv.dot(Inn**2)                  # [1 x Ne] ensemble objective function.

LH=np.exp(-0.5*EObj)                     # Scaled likelihood. 

# Calculate the posterior weights as the normalized likelihood. 
w=LH/sum(LH)                        # Posterior weights.

np.savetxt( wd + "/ensemble/weights.txt",w)
np.savetxt(wd + "/ensemble/HX", HX)
np.savetxt(wd + "/ensemble/HX_swe", HX_swe)
np.savetxt(wd + "/ensemble/obs", Y)
np.savetxt(wd + "/openloopMean.csv", oloop)

cmd = [ "Rscript",   "./rsrc/gridDA_FSM_hpc.R" , wd, str(N)]
subprocess.check_output(cmd)
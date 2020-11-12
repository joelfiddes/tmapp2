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
sdThresh=0
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

# loop over to do processing
data=[]
for eres in ensembleResults:
	ensembRes2 = pd.read_csv(eres, header=None)

	ensembRes2[ ensembRes2 <= sdThresh ] = 0
	ensembRes2[ ensembRes2 > sdThresh ] = 1
	Vect = lp.members
	arr = ensembRes2.transpose()*Vect
	HXi = arr.sum(axis=1)/sum(lp.members)
	data.append(HXi)

HX = np.asarray(data).transpose()

# make the real value matrix fro plotting
data=[]
for eres in ensembleResults:
	ensembRes2 = pd.read_csv(eres, header=None)
	ensembRes2[ensembRes2>1000]=1000
	Vect = lp.members
	arr = ensembRes2.transpose()*Vect
	HXi = arr.sum(axis=1)/sum(lp.members)
	data.append(HXi)

HX_swe = np.asarray(data).transpose()


# cut all values > 10000
# extract obs for da year
startIndex = fsca_dates[fsca_dates.iloc[:,0]==str(da_year)+"-03-31"].index.values     
endIndex = fsca_dates[fsca_dates.iloc[:,0]==str(da_year)+"-06-30"].index.values 

Y=fsca[int(startIndex):int(endIndex)]/100


# particle batch smoothert

No=len(Y)
Rinv=np.array([(1/R)]*No)
mat = np.ones((1,HX.shape[1])) 

# Calculate the likelihood.
Inn= np.kron(mat,Y) -HX

# with %*% gives NA
EObj=Rinv.dot(Inn**2)                  # [1 x Ne] ensemble objective function.

LH=np.exp(-0.5*EObj)                     # Scaled likelihood. 

# Calculate the posterior weights as the normalized likelihood. 
w=LH/sum(LH)                        # Posterior weights.

pd.Series(w).to_csv( wd + "/ensemble/weights.txt")
np.savetxt(wd + "/ensemble/HX", HX)
np.savetxt(wd + "/ensemble/HX_swe", HX_swe)
np.savetxt(wd + "/ensemble/obs", Y)

cmd = [ "Rscript",   "./rsrc/gridDA_FSM_hpc.R"]
subprocess.check_output(cmd)
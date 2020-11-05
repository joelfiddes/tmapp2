# run python tmapp_hpc_perturb.py #WD
import subprocess
import sys
import os
from configobj import ConfigObj

wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
config = ConfigObj(wd + "/config.ini")

# ===============================================================================
#	Make ensemble.csv (peturb pars)
# ===============================================================================

ensemb_dir = wd+"/ensemble"
N = config['ensemble']['members']

# Creat wd dir if doesnt exist
if not os.path.exists(ensemb_dir):
	os.makedirs(ensemb_dir)

# write copy of config for ensemble editing

#generate ensemble
subprocess.call(["Rscript", "rsrc/ensemGen.R" , str(N) , ensemb_dir, config['ensemble']['sampling'] ])

# copy FSm exe to wd
fsm=config['main']['FSMPATH'] + "/FSM"
cmd="cp " +fsm+ " " +wd
os.system(cmd)

# clean up old resamples from tmapp
for f in glob.glob(wd+"/out/"+ "*1D.csv"):
	os.remove(f)

# clean up old resamples
for f in glob.glob(wd+"/out/"+ "*1H.csv"):
	os.remove(f)

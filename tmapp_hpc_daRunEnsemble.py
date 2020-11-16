import subprocess
import sys
import os
from configobj import ConfigObj
import tmapp_da_FSM_hpc

wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
ensembleN=sys.argv[2]
daYear=sys.argv[3]
config = ConfigObj(wd + "/config.ini")

# ===============================================================================
#	Make ensemble.csv (peturb pars)
# ===============================================================================

   


#fname1 = wd + "/SUCCESS_ENSEMBLE"
#if not os.path.isfile(fname1):  # NOT ROBUST

ipad=   '%03d' % (int(ensembleN),)
successFile = wd + "/ensemble/ensemble" + str(ipad) + "/_RUN_SUCCESS"

if not os.path.isfile(successFile):  # NOT ROBUST
    print("----- START ENSEMBLE RUN " + str(ensembleN) + " -----")

    # run ensemble directory create and perturb code on ensemble i
    tmapp_da_FSM_hpc.main(wd, ensembleN, daYear)

    # write success file if ensemble completes
    f= open(successFile,"w+")
    f.close() 


#    f = open(wd + "/SUCCESS_ENSEMBLE", "w")
else:
    print("Ensemble "+ipad+ " simulated already")


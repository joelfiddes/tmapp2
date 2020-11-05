import subprocess
import sys
import os
from configobj import ConfigObj
import logging
import tmapp_da_FSM_hpc
wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 


config = ConfigObj(wd + "/config.ini")

logfile = wd+ "/LOG_DA"
if os.path.isfile(logfile) == True:
	os.remove(logfile)


# to clear logger: https://stackoverflow.com/questions/30861524/logging-basicconfig-not-creating-log-file-when-i-run-in-pycharm
for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

logging.basicConfig(level=logging.DEBUG, filename=logfile,filemode="a+",format="%(asctime)-15s %(levelname)-8s %(message)s")
# ===============================================================================
#	Make ensemble.csv (peturb pars)
# ===============================================================================

   
stephr=1  
fname1 = wd + "/SUCCESS_ENSEMBLE"
if not os.path.isfile(fname1):  # NOT ROBUST


    for ensembleN in tqdm(range(0, int(config['ensemble']['members']))):


        ipad=   '%03d' % (int(ensembleN),)
        successFile = wd + "/ensemble/ensemble" + str(ipad) + "/_RUN_SUCCESS"

        if not os.path.isfile(successFile):  # NOT ROBUST
            logging.info("----- START ENSEMBLE RUN " + str(ensembleN) + " -----")

            # run ensemble directory create and perturb code on ensemble i
            tmapp_da_FSM_hpc.main(wd, ensembleN, stephr)

            # write success file if ensemble completes
            f= open(successFile,"w+")
            f.close() 


    f = open(wd + "/SUCCESS_ENSEMBLE", "w")

else:
    logging.info("Ensemble simulated already")


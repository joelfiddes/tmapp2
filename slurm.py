#!/usr/bin/env python3
import os
import sys
sys.path.append(os.getcwd())

from joblib import Parallel, delayed
import numpy as np
import time
import sys
import logging
import glob
import tmapp_run
# inputs
num_cores = int(sys.argv[1]) # Must input number of cores
wd=sys.argv[2]


simdirs = (glob.glob1(wd+"/sim/","*"))
print("running jobs: "+str(simdirs))
members=[i.split("m", 1)[1] for i in simdirs]

njobs=len(simdirs)

Parallel(n_jobs=int(num_cores))(delayed(tmapp_run.main)(wd, simdirs[i], members[i]) for i in range(0,njobs))




# run python tmapp_hpc_perturb.py #WD
import sys
import os
import glob
import numpy as np
import pandas as pd
wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 


# ===============================================================================
#	Make ensemble.csv (peturb pars)
# ===============================================================================

# is making a massive df a good idea ?!

fname1 = wd + "/SUCCESS_RMAT"
if not os.path.isfile(fname1):  # NOT ROBUST
    print("Generate results matrix")


    # faster
    a =glob.glob(wd + "/ensemble/**/_RUN_SUCCESS")
    finishedsims = [os.path.split(i)[0] for i in a]
    myfiles = [glob.glob(i+"/out*") for i in finishedsims]
    flat_list = [item for sublist in myfiles for item in sublist]

    file_list = sorted(flat_list)  


    # Natural sort to get correct order ensemb * samples
	import re                                                                                                                                                                                                                                                             
 
    def natural_sort(l): 
    	convert = lambda text: int(text) if text.isdigit() else text.lower() 
        alphanum_key = lambda key: [ convert(c) for c in re.split('([0-9]+)', key) ] 
        return sorted(l, key = alphanum_key)
    
    fl_sort = natural_sort(file_list)


    data = []
    for file_path in tqdm(fl_sort):
            data.append( np.genfromtxt(file_path, usecols=6)   )
    myarray = np.asarray(data)
    df =pd.DataFrame(myarray)

    # 2d rep of 3d ensemble in batches where ensemble changes slowest
    df.to_csv( wd+'/ensembRes.csv', index = False, header=False)


    # FSMID="01"
    # cmd = [
    #     "Rscript",
    #     "./rsrc/resultsMatrix_fsm.R",
    #     home,
    #     config["ensemble"]["members"],
    #     str(FSMID)
    # ]
    # subprocess.check_output(cmd)

    f = open(wd + "/SUCCESS_RMAT", "w")

else:
    print("Results matrix already generated!")
                


# ===============================================================================
#	DA - run PBS grid code
# ===============================================================================
fname1 = home + "/SUCCESS_PBS2"
if not os.path.isfile(fname1):  # NOT ROBUST

    logging.info("Run PBS " + simdir)
    cmd = [
        "Rscript",
        "./rsrc/gridDA_FSM.R",
        home,
        config["ensemble"]["members"],
        config["main"]["startDate"],
        config["main"]["endDate"],
        config["da"]["startDate"],
        config["da"]["endDate"]
    ]
    subprocess.check_output(cmd)

    cmd = [
        "Rscript",
        "./rsrc/mapDaResults_fsm.R",
        home,
        config["ensemble"]["members"],
        'surface',
        'snow_water_equivalent.mm.',
        '263'
    ]

    subprocess.check_output(cmd)

    f = open(home + "/SUCCESS_PBS2", "w")

else:
    logging.info("PBS2 already run")
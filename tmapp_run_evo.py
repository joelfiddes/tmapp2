#!/usr/bin/env python

"""tmapp_run_mod.py


Example:

	joel@joel-ThinkPad-T440p:~/src/tmapp2$ python tmapp_run_evo.py /home/joel/sim/amu_evo/ g1


ARGS:
	wd:
	simdir:
	member=1 (HRES) or 1:n (EDA)
	model= SNOWPACK or GEOTOP
Todo:
 * make more modular 
 * replace inform with prescribed coeffs




"""

import sys
import os
import subprocess
import logging
from datetime import datetime, timedelta
from dateutil.relativedelta import *
import glob
from shutil import copyfile
import shutil
import sys
import time
from configobj import ConfigObj

# add to config
svf_sectors = str(8)  # sectors to search
svf_dist = str(5000)  # search distance m


def main(wd, simdir, model="GEOTOP"):
    # ===============================================================================
    #	Config setup
    # ===============================================================================
    # os.system("python writeConfig.py") # update config DONE IN run.sh file

    config = ConfigObj(wd + "/config.ini")

    tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory

    # config start and end date
    start = datetime.strptime(config['main']['startDate'], "%Y-%m-%d")
    end = datetime.strptime(config['main']['endDate'], "%Y-%m-%d")
    windCor = config['toposcale']['windCor']
    # ===============================================================================
    #	Log
    # ===============================================================================
    logfile = wd + "/sim/" + simdir + "/logfile"
    if os.path.isfile(logfile) == True:
        os.remove(logfile)
    logging.basicConfig(level=logging.DEBUG, filename=logfile, filemode="a+",
                        format="%(asctime)-15s %(levelname)-8s %(message)s")

    logging.info("Run script = " + os.path.basename(__file__))
    # ===============================================================================
    #	Check ele rules
    # ===============================================================================
    # minEle = config['main']['minEle']
    # cmd = ["Rscript", "./rsrc/computeSVF.R", home,svf_sectors, svf_dist]
    # subprocess.check_output(cmd)
    # ===============================================================================
    #	Timer
    # ===============================================================================
    start_time = time.time()

    # ===============================================================================
    #	make dirs
    # ===============================================================================
    home = wd + "/sim/" + simdir
    if not os.path.exists(home + "/forcing"):
        os.makedirs(home + "/forcing")

    # ===============================================================================
    #	CAtch complete runs
    # ===============================================================================
    fname = home + "SUCCESS_PBS"
    if os.path.isfile(fname) == True:
        sys.exit(simdir + " already done!")

    # ===============================================================================
    #	Copy coeffs.txt - to be placed in config
    # ===============================================================================
    src = config['main']['srcdir'] + "/coeffs.txt"
    dst = home + "/coeffs.txt"
    copyfile(src, dst)

    # ===============================================================================
    # Compute svf
    # ===============================================================================
    fname = home + "/predictors/svf.tif"
    if os.path.isfile(fname) == False:
        logging.info("Calculating SVF layer " + simdir)
        cmd = ["Rscript", "./rsrc/computeSVF.R", home, svf_sectors, svf_dist]
        subprocess.check_output(cmd)
    else:
        logging.info("SVF computed!")
    # ===============================================================================
    # Compute surface
    # ===============================================================================
    fname = home + "/predictors/surface.tif"
    if os.path.isfile(fname) == False:

        logging.info("Calculating surface layer " + simdir)
        cmd = ["Rscript", "./rsrc/makeSurface.R", home, str(0.3)]
        subprocess.check_output(cmd)
    else:
        logging.info("Surface already computed!")

    # ===============================================================================
    #	BLOCK XX
    #
    #	Code:
    #	- toposub_post.R
    #	- toposub_inform.R
    #   - sampleDistributions.R
    #   - modalSurface.R
    #
    #   Memory: HIGH (around 3GB for ERA5 grid cell)
    #	Runtime: LOW
    #
    # ===============================================================================

    # ===============================================================================
    #	Run toposub
    # ===============================================================================
    fname = home + "/SUCCESS_TSUB"
    if not os.path.isfile(fname):

        logging.info("Run TopoSUB! " + simdir)
        cmd = [
            "Rscript",
            "./rsrc/toposub_evo.R",
            home,
            config['toposub']['nclust'],
            "TRUE",
            "TRUE"
        ]
        subprocess.check_output(cmd)

        logging.info("TopoSUB complete")

        # sample dist plots
        src = "./rsrc/sampleDistributions.R"
        arg1 = home
        arg2 = config['toposcale']['svfCompute']
        arg3 = "sampDistInfm.pdf"
        cmd = "Rscript %s %s %s %s" % (src, arg1, arg2, arg3)
        os.system(cmd)

        logging.info("Assign surface types")
        cmd = [
            "Rscript",
            "./rsrc/modalSurface.R",
            home
        ]
        subprocess.check_output(cmd)
        f = open(home + "/SUCCESS_TSUB", "w")
    else:
        logging.info("TopoSUB already run " + simdir)

    # =========================   END of memeber 1 only section   ===============

    # ===============================================================================
    # Define start/endtime - still need this?
    # ===============================================================================
    start = datetime.strptime(config['main']['startDate'], "%Y-%m-%d")
    end = datetime.strptime(config['main']['endDate'], "%Y-%m-%d")

    # Redefine starttime in case sim is restarted
    startTime = (
            str('{0:04}'.format(start.year)) + "-"
            + str('{0:02}'.format(start.month)) + "-"
            + str('{0:02}'.format(start.day)) + " "
            + str('{0:02}'.format(start.hour)) + ":"
            + str('{0:02}'.format(start.minute)) + ":"
            + str('{0:02}'.format(start.second))
    )

    # TReset to full length endtime
    endTime = (
            str('{0:04}'.format(end.year)) + "-"
            + str('{0:02}'.format(end.month)) + "-"
            + str('{0:02}'.format(end.day)) + " "
            + str('{0:02}'.format(end.hour)) + ":"
            + str('{0:02}'.format(end.minute)) + ":"
            + str('{0:02}'.format(end.second))
    )

    # ===============================================================================
    #	BLOCK XX
    #
    #	Code:
    #	- tscale_run_EDA.py /tscale_run.py
    #	- met2geotop.R
    #	Memory: LOW
    #	Runtime: HIGH
    #
    # ===============================================================================

    # ===============================================================================
    #	Run toposcale
    # ===============================================================================
    if config["toposcale"]["mode"] == "3d":

        fname1 = home + "/SUCCESS_TSCALE"
        if os.path.isfile(fname1) == False:  # NOT ROBUST

            if config["forcing"]["product"] == "reanalysis":
                logging.info("Run TopoSCALE " + simdir)

                cmd = [
                    "python",
                    tscale_root + "/tscaleV2/toposcale/tscale3Dtsub.py",
                    home,
                    wd + "/forcing/",
                    "point",
                    config['main']['startDate'],
                    config['main']['endDate'],
                    "HRES",
                    "1"
                ]

            subprocess.check_output(cmd)

            f = open(home + "/SUCCESS_TSCALE", "w")
        else:
            logging.info("TSCALE 3d already run " + simdir)

    if config["toposcale"]["mode"] == "1d":
        fname1 = home + "/SUCCESS_TSCALE"
        if os.path.isfile(fname1) == False:  # NOT ROBUST

            if config["forcing"]["product"] == "reanalysis":
                logging.info("Run TopoSCALE " + simdir)

                cmd = [
                    "python",
                    tscale_root + "/tscaleV2/toposcale/tscale_run.py",
                    wd + "/forcing/",
                    home, home + "/forcing/",
                    startTime,
                    endTime,
                    windCor,
                    config['forcing']['dataset'],
                    config['toposcale']['plapse']
                ]

            subprocess.check_output(cmd)
            f = open(home + "/SUCCESS_TSCALE", "w")
        else:
            logging.info("TSCALE 1d already run " + simdir)

    if config["toposcale"]["mode"] == "basins":
        basinID = simdir.split('g', 1)[1]

        fname1 = home + "/SUCCESS_TSCALE"
        if os.path.isfile(fname1) == False:  # NOT ROBUST

            if config["forcing"]["product"] == "reanalysis":
                logging.info("Run TopoSCALE basin " + simdir)

                cmd = [
                    "python",
                    tscale_root + "/tscaleV2/toposcale/tscale_run_basin.py",
                    wd + "/forcing/",
                    home,
                    home + "/forcing/",
                    startTime,
                    endTime,
                    windCor,
                    basinID,
                    config['toposcale']['plapse']
                ]

            subprocess.check_output(cmd)
            f = open(home + "/SUCCESS_TSCALE", "w")
        else:
            logging.info("TSCALE basin already run " + simdir)

    if config["toposcale"]["mode"] == "basinsBLIN":
        basinID = simdir.split('g', 1)[1]

        fname1 = home + "/SUCCESS_TSCALE"
        if os.path.isfile(fname1) == False:  # NOT ROBUST

            if config["forcing"]["product"] == "reanalysis":
                logging.info("Run TopoSCALE basin " + simdir)

                cmd = [
                    "python",
                    tscale_root + "/tscaleV2/toposcale/tscale_run_basin2.py",
                    wd + "/forcing/",
                    home,
                    home + "/forcing/",
                    startTime,
                    endTime,
                    windCor,
                    basinID,
                    config['toposcale']['plapse']
                ]

            subprocess.check_output(cmd)
            f = open(home + "/SUCCESS_TSCALE", "w")
        else:
            logging.info("TSCALE basin already run " + simdir)

    # ===============================================================================
    #	BLOCK XX
    #
    #	Code:
    #	- setupSim.R
    #	- makeGeotopInputs.R
    #	- Call Geotop
    #	Memory: LOW
    #	Runtime: HIGH
    #
    # ===============================================================================

    # ===============================================================================
    #	Prepare inputs
    # ===============================================================================

    fname1 = home + "/SUCCESS_SIM"
    if os.path.isfile(fname1) == False:  # NOT ROBUST

        logging.info("Generating Toposcale geotop met files " + simdir)
        tsfiles = glob.glob(home + "/forcing/*.csv")

        for tsfile in tsfiles:
            cmd = ["Rscript", "./rsrc/met2geotop.R", tsfile]
            subprocess.check_output(cmd)

        ''' check for geotop run complete files - we check for .old files as
        this shows geotop has run successfully twice, 

        however '_SUCCESSFUL_RUN.old' is generated upon start of second sim by 
        renaming _SUCCESSFIL_RUN to _SUCCESSFIL_RUN.old. this means if sim fails 
        then _SUCCESSFIL_RUN.old exists but no _SUCCESSFIL_RUN file. Also  a  _FAILED_RUN 
        file is generated. tHEREFORE:

        _SUCCESSFUL_RUN + _SUCCESSFUL_RUN.old = SIM2 SUCCEEDED
        _SUCCESSFIL_RUN.old + _FAILED_RUN = SIM2 FAILED

        If sims failing clear all _SUCCESSFUL_RUN files to start over:
        find . -maxdepth 4 -name "_SUCCESSFUL_RUN" |xargs rm 
        '''
        runCounter = 0
        foundsims = []
        for root, dirs, files in os.walk(home):
            for file in files:
                if file.endswith('_SUCCESSFUL_RUN'):
                    runCounter += 1
                    foundsims.append(os.path.join(root, file))

        fsims = [i.split('/', 2)[1] for i in foundsims]

        # case of no sims and probably no setup done
        if runCounter == 0:

            logging.info("prepare sim directories")
            cmd = ["Rscript", "./rsrc/setupSim.R", home]
            subprocess.check_output(cmd)

            logging.info("prepare geotop.inpts")
            cmd = [
                "Rscript",
                "./rsrc/makeGeotopInputs.R",
                home,
                config["main"]["srcdir"] + "/geotop/geotop.inpts",
                config["main"]["startDate"],
                config["main"]["endDate"]
            ]
            subprocess.check_output(cmd)

            # ===============================================================================
            #	Simulate results
            #
            # ===============================================================================
            sims = glob.glob(home + "/c0*")
            sims = sorted(sims)
            for sim in sims:
                logging.info("run geotop" + sim)
                cmd = ["./geotop/geotop1.226", sim]
                subprocess.check_output(cmd)

                # clean up sim dirs for efficiency
                fname1 = sim + "/meteo0001.txt.old"  # look for possible meteo old files
                if os.path.isfile(fname1) == True:  # NOT ROBUST
                    os.remove(fname1)

                os.remove(sim + "/geotop.log")  # rm log
                shutil.rmtree(sim + "/rec")  # rm unused rec folder

        # case of incomplete sims
        if runCounter != int(config['toposub']['nclust']) and runCounter > 0:
            logging.info("only " + str(runCounter) + " complete sims found, these sims left to run:")

            # all sims to run
            sims = glob.glob(home + "/c0*")
            sims = [i.split('/', 1)[1] for i in sims]
            # fsims = found complemete sims
            # list only files that dont exist
            sims2do = [x for x in sims if x not in fsims]
            logging.info(sims2do)

            for sim in sims2do:
                # add back leading slash
                sim = "/" + sim
                logging.info("run geotop " + sim)
                cmd = ["./geotop/geotop1.226", sim]
                subprocess.check_output(cmd)

        # ===============================================================================
        #	Generate aggregated results
        # ===============================================================================
        # logging.info( "Generate spatial mean " +simdir)
        # cmd = [
        # "Rscript",
        # "./rsrc/toposub_spatial_mean.R",
        # home ,
        # config["toposub"]["nclust"],
        # 'surface.txt',
        # 'snow_water_equivalent.mm.',
        # config["main"]["startDate"],
        # config["main"]["endDate"]
        # ]
        # subprocess.check_output(cmd)

        # ===============================================================================
        #	Generate max results
        # ===============================================================================

        f = open(home + "/SUCCESS_SIM", "w")
    else:
        logging.info("SIM already run  " + simdir)

    logging.info("Simulation finished! " + simdir)

    fname1 = home + "/snow_water_equivalent.mm.maxSWE.tif"
    if os.path.isfile(fname1) == False:  # NOT ROBUST

        logging.info("Generate spatial max " + simdir)
        cmd = [
            "Rscript",
            "./rsrc/toposubSpatialNow.R",
            home,
            config["toposub"]["nclust"],
            'snow_water_equivalent.mm.',
            config["toposub"]["spatialDate"]
        ]
        subprocess.check_output(cmd)

    # ===============================================================================
    #	Make ensemble
    # ===============================================================================
    if config["ensemble"]["run"] == "TRUE":

        fname1 = home + "/SUCCESS_PERTURB"
        if os.path.isfile(fname1) == False:  # NOT ROBUST

            import tmapp_da_gen
            tmapp_da_gen.main(wd, home)

            f = open(home + "/SUCCESS_PERTURB", "w")

        else:
            logging.info("Ensemble already generated")
        # ===============================================================================
        #	Simulate results
        # ===============================================================================

        fname1 = home + "/SUCCESS_ENSEMBLE"
        if not os.path.isfile(fname1):  # NOT ROBUST

            # loop through ensemble members
            for i in range(0, int(config['ensemble']['members'])):

                logging.info("----- START ENSEMBLE RUN " + str(i) + " -----")

                # run ensemble directory create and perturb code on ensemble i
                import tmapp_da_setup
                tmapp_da_setup.main(wd, home, i)

                sims = glob.glob(home + "/ensemble/ensemble" + str(i) + "/*")
                sims = sorted(sims)
                logging.info("sims to run= ")
                logging.info(sims)
                for sim in sims:

                    # check for sim thats completed
                    fname1 = sim + "/out/_SUCCESSFUL_RUN.old"
                    if os.path.isfile(fname1) == False:
                        logging.info("Now running " + sim)
                        cmd = ["./geotop/geotop1.226", sim]
                        subprocess.check_output(cmd)

                        # clean up sim dirs for space efficiency
                        fname1 = sim + "/meteo0001.txt.old"  # look for possible meteo old files
                        if os.path.isfile(fname1) == True:  # NOT ROBUST
                            os.remove(fname1)
                        fname1 = sim + "/out/discharge.txt"  # look for possible discharge files
                        if os.path.isfile(fname1) == True:  # NOT ROBUST
                            os.remove(fname1)

                        fname1 = sim + "/out/RS_Tmean.txt"  # look for possible discharge files
                        if os.path.isfile(fname1) == True:  # NOT ROBUST
                            os.remove(fname1)
                        os.remove(sim + "/meteo0001.txt")
                        os.remove(sim + "/listpoints.txt")
                        os.remove(sim + "/geotop.inpts")
                        os.remove(sim + "/geotop.log")  # rm log
                        shutil.rmtree(sim + "/hor")  # rm unused rec folder
                        if os.path.exists(sim + "/rec"):
                            shutil.rmtree(sim + "/rec")  # rm unused rec folder


                else:
                    logging.info(sim + " already run")
            f = open(home + "/SUCCESS_ENSEMBLE", "w")

        else:
            logging.info("Ensemble simulated already")
        # ===============================================================================
        #	DA - ensemble
        # ===============================================================================
        fname1 = home + "/SUCCESS_PBS"
        if not os.path.isfile(fname1):  # NOT ROBUST
            logging.info("Generate results matrix " + simdir)
            cmd = [
                "Rscript",
                "./rsrc/resultsMatrix_pbs.R",
                home,
                config["ensemble"]["members"],
                'surface',
                'snow_water_equivalent.mm.',
            ]
            subprocess.check_output(cmd)

            # ===============================================================================
            #	Prepare MODIS obs
            # ===============================================================================
            # requires that files exist in wd
            # downloaded MOD and MYD using MODIStsp tool

            fname1 = home + "/fsca_stack.tif"
            if not os.path.isfile(fname1):  # NOT ROBUST
                logging.info("prepare MODIS OBS")
                cmd = [
                    "Rscript",
                    "./rsrc/extractSCATimeseriesGRID.R",
                    home,
                    wd + '/da',

                ]
                subprocess.check_output(cmd)
            f = open(home + "/SUCCESS_PBS", "w")

        else:
            logging.info("PBS already run")
        # ===============================================================================
        #	DA - run PBS grid code
        # ===============================================================================
        fname1 = home + "/SUCCESS_PBS2"
        if not os.path.isfile(fname1):  # NOT ROBUST

            logging.info("Run PBS " + simdir)
            cmd = [
                "Rscript",
                "./rsrc/gridDA.R",
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
                "./rsrc/mapDaResults.R",
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

    # crop out modis tile stack
    # run gridDA

    logging.info("Simulation " + home + " finished!")
    logging.info(" %f minutes for total run" % round((time.time() / 60 - start_time / 60), 2))


# ===============================================================================
#	Calling Main
# ===============================================================================
if __name__ == '__main__':
    wd = sys.argv[1]
    simdir = sys.argv[2]
    main(wd, simdir)

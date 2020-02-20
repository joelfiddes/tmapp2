#!/usr/bin/env python

"""tmapp_run_points.py


Example:

	joel@joel-ThinkPad-T440p:~/src/tmapp2$ python tmapp_run_points.py /home/joel/sim/imis/ SNOWPACK 1D


ARGS:
	wd: workdir
	model= SNOWPACK or GEOTOP
	interp:
Todo:




"""
from tqdm import tqdm
import sys
import os
import subprocess
import logging
from datetime import datetime, timedelta
from dateutil.relativedelta import *
import glob
from shutil import copyfile
import sys
import time
import pandas as pd
from configobj import ConfigObj
import re
import netCDF4 as nc
import numpy as np


def main(wd, model="SNOWPACK", interp='1D'):
    print("Toposcale= " + interp)
    print("Model= " + model)
    # ===============================================================================
    # Config setup
    # ===============================================================================
    # os.system("python writeConfig.py") # update config DONE IN run.sh file

    config = ConfigObj(wd + "/config.ini")
    tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory

    # config start and end date
    start = datetime.strptime(config['main']['startDate'], "%Y-%m-%d")
    end = datetime.strptime(config['main']['endDate'], "%Y-%m-%d")
    windCor = config['toposcale']['windCor']
    # ===============================================================================
    # Log
    # ===============================================================================
    # logfile=wd+"/sim/"+ simdir+"/logfile"
    logfile = wd + "/logfile"
    if os.path.isfile(logfile):
        os.remove(logfile)
    logging.basicConfig(level=logging.DEBUG, filename=logfile, filemode="a+",
                        format="%(asctime)-15s %(levelname)-8s %(message)s")

    logging.info("Run script =" + os.path.basename(__file__))
    # ===============================================================================
    #	Timer
    # ===============================================================================
    start_time = time.time()

    # ===============================================================================
    #	make dirs
    # ===============================================================================
    home = wd  # +"/sim/"+simdir
    if not os.path.exists(home + "/forcing"):
        os.makedirs(home + "/forcing")

    # make out path for results
    out = home + "/out/" + model
    if not os.path.exists(out):
        os.makedirs(out)

    # ===============================================================================
    #	Init ensemble memebers from memeber =1
    # ===============================================================================
    '''copy 
    -listpoints

    '''

    # if int(member) > 1:
    # 	ngrid = simdir.split("m")[0]
    # 	master= wd + '/sim/' + ngrid + 'm1'
    # 	src=master +"/listpoints.txt"
    # 	dst= home+"/listpoints.txt"
    # 	copyfile(src,dst)
    # 	src=master +"/landcoverZones.txt"
    # 	dst= home+"/landcoverZones.txt"
    # 	copyfile(src,dst)
    # 	src=master +"/landform.tif"
    # 	dst= home+"/landform.tif"
    # 	copyfile(src,dst)

    # if int(member) == 1:
    # =========================  start of memeber 1 only section   ==================


    # ===============================================================================
    #  Time stuff
    # ===============================================================================
    # time stuff
    f = nc.Dataset(home + "/forcing/SURF.nc")
    nctime = f.variables['time']
    dtime = pd.to_datetime(nc.num2date(nctime[:],nctime.units, calendar="standard"))
    starti = np.asscalar(np.where(dtime==start)[0]) # so can run on a single timestep
    print(end)
    endi = np.asscalar(np.where(dtime==end)[0]) 
    year = dtime.year[0] 

    # compute timestep before we cut timeseries
    a=dtime[2]-dtime[1]
    step = a.seconds
    stephr=step/(60*60)
    # extract timestep

    # ===============================================================================
    #	Compute svf
    # ===============================================================================

    fname = home + "/predictors/svf.tif"
    if not os.path.isfile(fname):
        logging.info("Calculating SVF layer ")
        cmd = ["Rscript", "./rsrc/computeSVF.R", home, config['toposcale']['svfSectors'], config['toposcale']['svfMaxDist']]
        subprocess.check_output(cmd)
    else:
        logging.info("SVF computed!")
    # ===============================================================================
    #	Compute surface
    # ===============================================================================
    fname = home + "/predictors/surface.tif"
    if not os.path.isfile(fname):

        logging.info("Calculating surface layer")
        cmd = ["Rscript", "./rsrc/makeSurface.R", home, str(0.3)]
        subprocess.check_output(cmd)
    else:
        logging.info("Surface already computed!")
    # ===============================================================================
    #	Run compute listpoints
    # ===============================================================================
    fname = home + "/listpoints.txt"
    if not os.path.isfile(fname):

        logging.info("Compute listpoints")
        cmd = ["Rscript", "./rsrc/makeListpoints2.R", home, config['main']['pointsShp']]
        subprocess.check_output(cmd)
        f = open(home + "/SUCCESS_LISTPOINTS", "w")
    else:
        logging.info("Listpoints already made!")
    # ===============================================================================
    #	Run toposcale
    # ===============================================================================



    '''check for complete forcing/meteo* files==nclust'''
    meteoCounter = len(glob.glob1(home + "/forcing/", "*.csv"))
    lp = pd.read_csv(home + "/listpoints.txt")

    if meteoCounter != len(lp.name):

        if config['main']['runmode'] == 'points':

            if config["forcing"]["product"] == "reanalysis":

                # 2d
                if interp == '1D':
                    cmd = [
                        "python",
                        tscale_root + "/tscaleV2/toposcale/tscale_run.py",
                        wd + "/forcing/",
                        home,
                        home + "/forcing/",
                        config['main']['startDate'],
                        config['main']['endDate'],
                        windCor,
                        config['forcing']['dataset'],
                        config['toposcale']['plapse']
                    ]

                # logging.info( "Run TopoSCALE points reanalysis")

                # #3d
                if interp == '3D':
                    cmd = [
                        "python",
                        tscale_root + "/tscaleV2/toposcale/tscale3D.py",
                        wd,
                        config['main']['runmode'],
                        config['main']['startDate'],
                        config['main']['endDate'],
                        "HRES",
                        '1'

                    ]

        subprocess.check_output(cmd)

        # report sucess
        f = open(home + "/SUCCESS_TSCALE1", "w")
    else:
        logging.info("Toposcale 1 already run " + str(len(lp.name)) + " meteo files found")

    # list of toposcale generated forcing files with full path
    files = glob.glob(home + "/forcing/*.csv")
    print(files)

    # ===============================================================================
    #   Prepare FSM (SSM) meteo file
    # ===============================================================================
    if model == "FSM1":
        logging.info("Convert met to FSM format...")
        # make geotop met files
        for file in files:
            file = os.path.basename(file)  # remove path
            cmd = ["Rscript", "./rsrc/met2fsm.R", home + "/forcing/" + file] # has to write to forcing so setupSim can work
            subprocess.check_output(cmd)

            for i in range(0,32):
                nconfig=str(i)
            # write namelist
                nlst = open(home+"nlst_tmapp.txt","w") 

                str1="! namelists for running FSM with the Col de Porte example"
                str2="\n&config"
                str18="\n  nconfig="+nconfig
                str3="\n/"
                str4="\n&drive"
                str5="\n  met_file ='"+home+"forcing/"+file+"_fsm.txt'"
                str6="\n  zT = 1.5"
                str7="\n  zvar = .FALSE."
                str8="\n/"
                str9="\n&params"
                str10="\n/"
                str11="\n&initial"
                str12="\n  Tsoil = 282.98 284.17 284.70 284.70"
                str13="\n/"
                str14="\n&outputs"
                str15="\n  out_file = '"+home+"out/"+model+"/"+file+nconfig+"out.txt'"
                str16="\n  Nave=8"
                str17="\n/\n"

                logging.info(str15)
                logging.info(str5)
                L = [str1, str2, str18, str3, str4, str5, str6, str7, str8, str9, str10, str11,str12,str13,str14,str15,str16,str17] 
                nlst.writelines(L)
                nlst.close() 

                logging.info(str15)
                # run model
                fsm="/home/joel/src/tmapp2/fsm/FSM"
                cmd=fsm+ " < " +home+"nlst_tmapp.txt"
                logging.info(cmd)
                os.system(cmd)


    if model=='FSM':

        # copy executable to wd so can specify relative paths in config 
        # to avoid longname failure (63char limit)
        fname1 = home + "/SUCCESS_SIM"
        if os.path.isfile(fname1) == False:  # NOT ROBUST
            print('FSM simulation')
            fsm=config['main']['FSMPATH'] + "/FSM"
            cmd="cp " +fsm+ " " +wd
            os.system(cmd)

            # list of toposcale generated forcing files with full path
            tsfiles = glob.glob(home + "/forcing/*.csv")
            #timestep = int(config["forcing"]["step"]) *60*60 # forcing in seconds 




            tout=24/(step/60/60)
            logging.info("Convert met to FSM format...")
            # make fsm met files
            for file in tqdm(tsfiles):
                file = os.path.basename(file)  # remove path
                cmd = ["Rscript", "./rsrc/met2fsm.R", home + "/forcing/" + file] # has to write to forcing so setupSim can work
                subprocess.check_output(cmd)

                # get id of file
                a  = file.split('.')[0]                                                                                                                
                fileID ='%03d' % (int(a.split('meteoc')[1]), )
                fsmFilename="fsm"+ str(fileID)+".txt"

                for i in range(0,31):
                    nconfig=str(i)
                    nconfig2='%02d' % (i,) # fixed width for filename sorting

                # write namelist
                    nlst = open(home+"/nlst_tmapp.txt","w") 

                    str1="! namelists for running FSM "
                    str2="\n&config"
                    str18="\n  nconfig="+nconfig
                    str3="\n/"
                    str4="\n&drive"
                    str5="\n  met_file ='./forcing/"+fsmFilename+"'"
                    str6="\n  zT = 1.5"
                    str7="\n  zvar = .FALSE."
                    str8="\n/"
                    str9="\n&params"
                    str10="\n/"
                    str11="\n&initial"
                    str12="\n  Tsoil = 282.98 284.17 284.70 284.70"
                    str13="\n/"
                    str14="\n&outputs"
                    str15="\n  out_file ='./out/"+model+"/"+fsmFilename+"_"+nconfig2+".txt'"
                    str16="\n  Nave=" +str(tout)
                    str17="\n/\n"


                    L = [str1, str2, str18, str3, str4, str5, str6, str7, str8, str9, str10, str11,str12,str13,str14,str15,str16,str17] 
                    nlst.writelines(L)
                    nlst.close() 

                    logging.info(str15)
                    # run model
                    os.chdir(wd)
                    fsm="./FSM"
                    cmd=fsm+ " < " +home+"/nlst_tmapp.txt"
                    print(cmd)
                    os.system(cmd)
                    os.chdir(config['main']['srcdir'])
            #f = open(home + "/SUCCESS_SIM", "w")
        else:
            logging.info("SIM already run  " + home)

    # ===============================================================================
    #	Prepare GEOTOP meteo file
    # ===============================================================================
    if model == "GEOTOP":
        logging.info("Convert met to geotop format...")
        # make geotop met files
        for file in files:
            file = os.path.basename(file)  # remove path
            cmd = ["Rscript", "./rsrc/met2geotop.R", home + "/forcing/" + file] # has to write to forcing so setupSim can work
            subprocess.check_output(cmd)

    # ===============================================================================
    #	Prepare SNOWPACK SMET INI and SNO - use direct confiobj inserts here
    # ===============================================================================
    if model == "SNOWPACK":
        logging.info("Preparing snowpack inputs...")

        # parse listpoints to get metadata
        lp = pd.read_csv(home + "/listpoints.txt")

        # make smet ini here
        # configure any additional / resampling /  QC here
        for file in files:
            file = os.path.basename(file)  # remove path
            logging.info("Now running " + file)
            # parse the file name to get id, -1 to get py index
            res = os.path.basename(file).split('.')[0]
            id = int(os.path.basename(res).split('meteoc')[1]) - 1

            cmd = ["Rscript", "./rsrc/sp_makeInputs.R",
                   config["main"]["srcdir"] + "/snowpack/",
                   home + '/forcing/',
                   file,
                   config['main']['startDate'], 'dummy']  # test to see if overidden by below - NOW redundent??
            subprocess.check_output(cmd)

            # quick fix to ensure second meteopath correctly configured
            # todo: cover all ini settins like this

            fileini = home + '/forcing/' + os.path.basename(file).split('.')[0] + ".ini"
            print(fileini)
            configini = ConfigObj(fileini)
            configini['Output']['METEOPATH'] = home + '/forcing/'
            configini['Input']['POSITION1'] = "latlon " + str(lp.lat[id]) + ", " + str(lp.lon[id]) + " " + str(
                lp.ele[id])
            configini['Input']['CSV_NAME'] = lp.name[id]
            configini['Input']['CSV_AZI'] = lp.asp[id]
            configini['Input']['CSV_SLOPE'] = lp.slp[id]
            configini['Output']['EXPERIMENT'] = lp.name[id]
            configini.write()

            # stip out any quotations that stop snowpack parser
            with open(fileini, "r") as sources:
                lines = sources.readlines()
            with open(fileini, "w") as sources:
                for line in lines:
                    sources.write(re.sub(r'"', '', line))

            filesno = home + '/forcing/' + os.path.basename(file).split('.')[0] + ".sno"
            # replace date in sno file
            with open(filesno, "r") as sources:
                lines = sources.readlines()
            with open(filesno, "w") as sources:
                for line in lines:
                    sources.write(re.sub(r'1997-09-01T00:00', config['main']['startDate'] + 'T00:00', line))

        # run meteoio
        for file in files:
            fileini = os.path.basename(file).split('.')[0] + ".ini"
            cmd = [config["main"]["srcdir"] + "snowpack/data_converter " +
                   config['main']['startDate'] +
                   " " + config['main']['endDate'] +
                   " " + config['meteoio']['timestep'] + " " +
                   home + "/forcing/" + fileini]
            logging.info(cmd)
            subprocess.check_output(cmd, shell=True)
    # cleanup
    # meteotoremove = glob.glob("*.csv")
    # os.remove(meteotoremove)

    # ===============================================================================
    #	Prepare and run GEOTOP sims
    # ===============================================================================
    if model == "GEOTOP":
        ''' check for geotop run complete files'''

        runCounter = 0
        foundsims = []
        for root, dirs, files in os.walk(home):
            for file in files:
                if file.endswith('_SUCCESSFUL_RUN'):
                    runCounter += 1
                    foundsims.append(os.path.join(root, file))

        fsims = [i.split('/', 2)[1] for i in foundsims]

        fname1 = home + "/SUCCESS_SIM1"
        if os.path.isfile(fname1) == False:  # NOT ROBUST

            # case of no sims and probably no setup done
            if runCounter == 0:

                logging.info("prepare cluster sim directories")
                cmd = ["Rscript", "./rsrc/setupSim.R", home]
                subprocess.check_output(cmd)

                logging.info("Assign surface types")
                cmd = ["Rscript", "./rsrc/modalSurface_points.R", home]
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

                sims = glob.glob(home + "/c0*")

                for sim in sims:
                    logging.info("run geotop" + sim)
                    cmd = ["./geotop/geotop1.226", sim]
                    subprocess.check_output(cmd)

            # CASE OF incomplete sims to be restarted (prob interuppted by cluster runtime limit)
            if runCounter != len(lp.name) and runCounter > 0:
                logging.info("only " + str(runCounter) + " complete sims found, finishing now...")
                # all sims to run
                sims = glob.glob(home + "/c0*")
                sims = [i.split('/', 1)[1] for i in sims]
                # fsims = found complemete sims
                # list only files that dont exist
                sims2do = [x for x in sims if x not in fsims]

                for sim in sims2do:
                    logging.info("run geotop " + sim)
                    cmd = ["./geotop/geotop1.226", sim]
                    subprocess.check_output(cmd)

            f = open(home + "/SUCCESS_SIM1", "w")

        else:
            logging.info("Geotop 1 already run " + str(runCounter) +
                         " _SUCCESSFUL_RUN files found")

    # ===============================================================================
    #	Prepare and run Snowpack sims - need to add all restart stuff
    # ===============================================================================
    if model == "SNOWPACK":
        logging.info("Running SNOWPACK!")
        myinis = glob.glob(home + "/forcing/" + "*.ini")
        for myini in myinis:
            logging.info("Running SNOWPACK " + myini)
            cmd = ["snowpack -c " + myini + " -e " + config['main']['endDate']]
            subprocess.check_output(cmd, shell=True)


# ===============================================================================
#	Calling Main
# ===============================================================================
if __name__ == '__main__':
    wd = sys.argv[1]
    model = sys.argv[2]
    interp = sys.argv[3]
    main(wd, model, interp)

# # plot points
#  files = list.files(".","surface.txt", recursive=T)
#  par(mfrow=c(4,3))
#  for (i in files){
#  dat = read.csv(i)
#  plot(dat$snow_depth.mm.)
#  }

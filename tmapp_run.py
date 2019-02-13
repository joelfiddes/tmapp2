import sys
import os
import subprocess
import logging
from datetime import datetime, timedelta
from dateutil.relativedelta import *

wd = sys.argv[1]
simdir = sys.argv[2]

#===============================================================================
#	Config setup
#===============================================================================
#os.system("python writeConfig.py") # update config DONE IN run.sh file
from configobj import ConfigObj
config = ConfigObj(wd+"/config.ini")

#===============================================================================
#	Logging
#===============================================================================
logging.basicConfig(level=logging.DEBUG, filename="logfile"+simdir, filemode="a+",
                        format="%(asctime)-15s %(levelname)-8s %(message)s")

#===============================================================================
#	make dirs
#===============================================================================
home = wd+"/sim/"+simdir
if not os.path.exists(home + "/forcing"):
	os.makedirs(home + "/forcing")

#===============================================================================
#	Compute svf
#===============================================================================
logging.info( "Calculating SVF layer: ")
cmd = ["Rscript", "./rsrc/computeSVF.R", home,str(6), str(500)]
subprocess.check_output(cmd)

#===============================================================================
#	Compute surface
#===============================================================================
logging.info( "Calculating surface layer: ")
cmd = ["Rscript",  "./rsrc/makeSurface.R",home,str(0.3)]
subprocess.check_output(cmd)

#===============================================================================
#	Run toposub 1
#===============================================================================
logging.info( "Run TopoSUB 1 ")
cmd = ["Rscript",  "./rsrc/toposub.R",home,str(config['toposub']['nclust'])]
subprocess.check_output(cmd)

#===============================================================================
#	Run toposcale 1 - only 1 year
#===============================================================================
start = datetime.strptime(config['main']['startDate'], "%Y-%m-%d")
end = datetime.strptime(config['main']['endDate'], "%Y-%m-%d")
dateDiff=end-start

""" run informed toposub on just one year data for efficiency"""
if (dateDiff > 368):
	end = start+relativedelta(months=+12)

fname1 = gridpath + "/tPoint.txt"
fname2 = gridpath + "/rPoint.txt"
fname3 = gridpath + "/uPoint.txt"
fname4 = gridpath + "/vPoint.txt"
fname5 = gridpath + "/lwPoint.txt"
fname6 = gridpath + "/sol.txt"
fname7 = gridpath + "/pSurf_lapse.txt"

if ( os.path.isfile(fname1) == True 
	and os.path.isfile(fname2) == True 
	and os.path.isfile(fname3) == True 
	and os.path.isfile(fname4) == True 
	and os.path.isfile(fname5) == True 
	and os.path.isfile(fname6) == True 
	and os.path.isfile(fname7) == True): #NOT ROBUST
	logging.info( "TopoSCALE already run: " + os.path.basename(os.path.normpath(Ngrid)) )

else:
	logging.info( "Run TopoSCALE 1 ")
	cmd = ["python",  "/home/joel/src/tscaleV2/toposcale/tscale_run.py",
	"/home/joel/mnt/myserver/sim/yala3/forcing/PLEV.nc", 
	"/home/joel/mnt/myserver/sim/yala3/forcing/SURF.nc", 
	home+"/listpoints.txt", config["forcing"]["product"],str(0)]
	subprocess.check_output(cmd)

	import TMtoposcale

#===============================================================================
#	Simulate results - 1 year
#===============================================================================

#===============================================================================
#	Run toposub 2
#===============================================================================

#===============================================================================
#	Run toposcale 2
#===============================================================================

#===============================================================================
#	Simulate results
#===============================================================================
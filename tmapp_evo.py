# args
import sys
wd= sys.argv[1] #'/home/joel/sim/qmap/ch_tmapp_10/' 
use_mpi =True

from configobj import ConfigObj

config = ConfigObj(wd + "/config.ini")
tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory
sys.path.insert(1, tscale_root)

import glob
import tscale_lib as tlib
from tqdm import tqdm
from joblib import Parallel, delayed
import os
import tscale3D
import logging


# setup MPI
if use_mpi == True:
	# https://gist.github.com/joezuntz/7c590a8652a1da6dc4c9
	import mpi4py.MPI
	#find out which number processor this particular instance is,
	#and how many there are in total
	rank = mpi4py.MPI.COMM_WORLD.Get_rank()
	size = mpi4py.MPI.COMM_WORLD.Get_size()


# config
config = ConfigObj(wd + "/config.ini")
tscale_root = config['main']['tscale_root']  # path to tscaleV2 directory
tmapp_root=config['main']['srcdir'] 
#start = datetime.strptime(config['main']['startDate'], "%Y-%m-%d")
#end = datetime.strptime(config['main']['endDate'], "%Y-%m-%d")
windCor = config['toposcale']['windCor']
svfSectors = config['toposcale']['svfSectors']
svfMaxDist = config['toposcale']['svfMaxDist']
demRes = config["main"]["demRes"] 
demDir=config["main"]["demdir"]
forcing_grid =config["forcing"]["grid"]
latN = config["main"]["latN"]
latS = config["main"]["latS"]
lonE = config["main"]["lonE"]
lonW = config["main"]["lonW"]
num_cores = config["main"]["num_cores"]
nclust = config['toposub']['nclust']
tsub_mode = config["toposcale"]["mode"]
namelist="/home/joel/sim/qmap/ch_tmapp2/nlst_tmapp.txt"
fsmexepath = "/home/joel/src/topoCLIM/FSM"
start = "197908"
end = "201909"

# =========================================================================
#	Log
# =========================================================================
logfile = wd+ "/logfile"
if os.path.isfile(logfile) == True:
    os.remove(logfile)


# to clear logger: https://stackoverflow.com/questions/30861524/logging-basicconfig-not-creating-log-file-when-i-run-in-pycharm
for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

logging.basicConfig(level=logging.DEBUG, filename=logfile,filemode="a+",format="%(asctime)-15s %(levelname)-8s %(message)s")

logging.info("Running setup")

# make wd dirs
tlib.make_dirs(wd)

# Compute time step or era5 forcing
files = sorted(glob.glob(wd + "/forcing/SURF*.nc"))  
stephr = tlib.compute_timestep(files[0])

# make shape
tlib.make_poly(latN,latS,lonE,lonW,wd)

# get DEM
shp = wd +"/spatial/domain.shp"
tlib.download_dem(wd, demDir,shp, demRes)

# make terrain (need check here)
tlib.compute_terrain_ndvi( wd )

# make sim dirs and cookie cut ele,slf,asp,ndvi to them
tlib.setup_sim_dirs_grid(wd, forcing_grid)

# compute svf in parallel in homes
homes = tqdm(sorted(glob.glob(wd+"/sim/*")))
Parallel(n_jobs=int(num_cores))(delayed(tlib.compute_svf)(home, svfSectors, svfMaxDist) for home in homes)

# compute surface model
homes = tqdm(sorted(glob.glob(wd+"/sim/*")))
Parallel(n_jobs=int(num_cores))(delayed(tlib.compute_surface)(home) for home in homes)


# toposub
logging.info("Running TopoSUB")
homes = tqdm(sorted(glob.glob(wd+"/sim/*")))
Parallel(n_jobs=int(num_cores))(delayed(tlib.toposub)(tmapp_root, home, nclust)for home in homes)


# tscale
logging.info("Running TopoSCALE")
tscale3D.main(wd, start, end) 
# need to solve dotprod memory issue Kris?Help!
# i/o is quite costly eg 2000 files

# convert to FSM format
logging.info("Running FSM")
# Simulate FSM
meteofiles = tqdm(sorted(glob.glob(wd+"/out/tscale*.csv")))
Parallel(n_jobs=int(1))(delayed(tlib.fsm_sim)(meteofile,namelist,fsmexepath) for meteofile in meteofiles)
# Task toi be run on hyperion can not be run as a script as all would send as 
# simultneous sbacth jobs
 
WD = '/home/caduff/sim//ch_tmapp_50/'
 
WD = '/home/caduff/sim//c'
# = Prep =================================================================

# ensure comfig.ini exists in $WD
# ensure $WD/predictors/ndvi_modis.tif exists
# set env = $HOME/src/tmapp2 source bin/activate

# = Single job =================================================================

# gets dem, computes asp/slp and clips ndvi
# requires predictors/ndvi_modis.tif to exist
srun python tmapp_hpc_setup.py $WD

# = Parallel job by N era5 grids  ==============================================

#Edit:
#<SBATCH --array=1-6 >
# to be number of jobs to number of ERA5 grids
# python2 script: tmapp_hpc_svf.sh 
# computes, svf, surface toosub
sbatch slurm_svf.sh $WD 

# = Parallel job by N jobs (normally 100) x months ==============================

#Arg2 is a round number greater than number of months to compute in order to 
#paralise the tscale time loop - it is split into NMONTHS/PROCESSORS chuncks 
#eg 500/100 = max 5 jobs per processor
# perhaps edit #<SBATCH --array=1-100 >
# jobs per processor must be a whole number
sbatch slurm_tscale.sh $WD 100


# = Parallel job by N jobs (normally 100) x samples ============================

#Arg2 is a round number greater than number of samples to compute in order to 
#paralise the tscale time loop - it is split into SAMPLES/PROCESSORS chuncks 
#eg 1100/100 = max 11 jobs per processor
# perhaps edit #<SBATCH --array=1-100 >
# jobs per processor must be a whole number

sbatch slurm_sim.sh $WD 1200



python tmapp_hpc_perturb.py $WD

# number of ensembles declared in here
sbatch slurm_da.sh $WD

python tmapp_hpc_HX.py  $WD  2003
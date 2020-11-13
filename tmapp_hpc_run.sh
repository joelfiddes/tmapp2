WD = '/home/caduff/sim//ch_tmapp_50/'

#env = src/tmapp2source bin/activate

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

# = Parallel job by N jobs (normally 100)  ==============================================

#Arg2 is a round number greater than number of months to compute in order to 
#paralise the tscale time loop - it is split into NMONTHS/PROCESSORS chuncks 
#eg 500/100 = max 5 jobs per processor
# perhaps edit #<SBATCH --array=1-100 >
# jobs per processor must be a whole number
sbatch slurm_tscale.sh $WD 100


sbatch slurm_sim.sh $WD 1100
python tmapp_hpc_perturb.py $WD

# number of ensembles declared in here
sbatch slurm_da.sh $WD

python tmapp_hpc_HX.py  $WD  2003
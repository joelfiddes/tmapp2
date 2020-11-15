# Example bash tmapp_hpc_run.sh /home/caduff/sim/ccamm_inter 100 1200 2003

# Args:
#	$1: is working directory
# 	$2: number of months in sim rounded up to nearest 100
# 	$3: number of samples rounded up to nearest 100
# 	$4: data assimilation year corresponding to melt period

NGRIDS=6
NENSEMBLE=100
NJOBS=100

if [[ $# -eq 0 ]] ; then
    echo 'Working directory needed as Arg1'
    exit 0
fi

# clear logs
rm LOG*

# Job dependency doc 
# https://hpc.nih.gov/docs/job_dependencies.html

#sbatch --dependency=singleton --job-name=GroupA 
# = Prep =================================================================

# ensure comfig.ini exists in $WD
# ensure $WD/predictors/ndvi_modis.tif exists
# set env = $HOME/src/tmapp2 source bin/activate

# = Single job =================================================================

# gets dem, computes asp/slp and clips ndvi
# requires predictors/ndvi_modis.tif to exist

SBATCHID=$(sbatch slurm_setup.sh $1)
jid1=${SBATCHID//[!0-9]/}

# = Parallel job by N era5 grids  ==============================================

#Edit:
#<SBATCH --array=1-6 >
# number of jobs to number of ERA5 grids
# python2 script: tmapp_hpc_svf.sh 
# computes, svf, surface toosub

# array = number grids
SBATCHID=$(sbatch  --dependency=afterany:$jid1 --array=1-$NGRIDS  slurm_svf.sh $1)
jid2=${SBATCHID//[!0-9]/}

# = Parallel job by N jobs (normally 100) x months ==============================

#Arg2 is a round number greater than number of months to compute in order to 
#paralise the tscale time loop - it is split into NMONTHS/PROCESSORS chuncks 
#eg 500/100 = max 5 jobs per processor
# perhaps edit #<SBATCH --array=1-100 >
# jobs per processor must be a whole number

# array = reasonable number
SBATCHID=$(sbatch  --dependency=afterany:$jid2 --array=1-$NJOBS slurm_tscale.sh $1 $2)
jid3=${SBATCHID//[!0-9]/}

# = Parallel job by N jobs (normally 100) x samples ============================

#Arg2 is a round number greater than number of samples to compute in order to 
#paralise the tscale time loop - it is split into SAMPLES/PROCESSORS chuncks 
#eg 1200/100 = max 12 jobs per processor
# perhaps edit #<SBATCH --array=1-100 >
# jobs per processor must be a whole number

# array = reasonable number
SBATCHID=$(sbatch  --dependency=afterany:$jid3  --array=1-$NJOBS slurm_sim.sh $1 $3)
jid4=${SBATCHID//[!0-9]/}



# Generate meteo purturbations 
SBATCHID=$(sbatch  --dependency=afterany:$jid4  --array=1 slurm_perturb.sh $1)
jid5=${SBATCHID//[!0-9]/}

# run ensembles get results, array = number of ensembles (in config.ini)
SBATCHID=$(sbatch  --dependency=afterany:$jid5  --array=1-$NENSEMBLE slurm_da.sh $1 $4)
jid6=${SBATCHID//[!0-9]/}

# compute mean Modis fSCA
SBATCHID=$(sbatch  --dependency=afterany:$jid6 --array=1 slurm_modis.sh $1)
jid7=${SBATCHID//[!0-9]/}

# run PBS and plots
SBATCHID=$(sbatch  --dependency=afterany:$jid7 --array=1 slurm_pbs.sh  $1  $4)
jid8=${SBATCHID//[!0-9]/}


squeue -u caduff
# Example ./tmapp_hpc_run.sh /home/caduff/sim/ccamm_inter 100 1200 2003

# Args:
#	$1: is working directory
# 	$2: number of months in sim rounded up to nearest 100
# 	$3: number of samples rounded up to nearest 100
# 	$4: data assimilation year corresponding to melt period

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
echo SBATCHID
# = Parallel job by N era5 grids  ==============================================

#Edit:
#<SBATCH --array=1-6 >
# to be number of jobs to number of ERA5 grids
# python2 script: tmapp_hpc_svf.sh 
# computes, svf, surface toosub

SBATCHID=$(sbatch  --dependency=afterany:$jid1 slurm_svf.sh $1)
jid2=${SBATCHID//[!0-9]/}
echo SBATCHID
# = Parallel job by N jobs (normally 100) x months ==============================

#Arg2 is a round number greater than number of months to compute in order to 
#paralise the tscale time loop - it is split into NMONTHS/PROCESSORS chuncks 
#eg 500/100 = max 5 jobs per processor
# perhaps edit #<SBATCH --array=1-100 >
# jobs per processor must be a whole number



SBATCHID=$(sbatch  --dependency=afterany:$jid2 slurm_tscale.sh $1 $2)
jid3=${SBATCHID//[!0-9]/}
echo SBATCHID
# = Parallel job by N jobs (normally 100) x samples ============================

#Arg2 is a round number greater than number of samples to compute in order to 
#paralise the tscale time loop - it is split into SAMPLES/PROCESSORS chuncks 
#eg 1200/100 = max 12 jobs per processor
# perhaps edit #<SBATCH --array=1-100 >
# jobs per processor must be a whole number

# echo "Run sim..."
# sbatch --dependency=singleton --job-name=tscale  slurm_sim.sh $1 $3
# echo "Done!"

SBATCHID=$(sbatch  --dependency=afterany:$jid3  slurm_sim.sh $1 $3)
jid4=${SBATCHID//[!0-9]/}
echo SBATCHID


# echo "Perturb parameters..."
# sbatch --dependency=singleton --job-name=fsm slurm_perturb.sh $1
# echo "Done!"

SBATCHID=$(sbatch  --dependency=afterany:$jid4  slurm_perturb.sh $1)
jid5=${SBATCHID//[!0-9]/}
echo SBATCHID

# number of ensembles declared in here

# echo "Simulate ensembles"
# sbatch --dependency=singleton --job-name=perturb slurm_da.sh $1 $4
# echo "Done!"
SBATCHID=$(sbatch  --dependency=afterany:$jid5  slurm_da.sh $1 $4)
jid6=${SBATCHID//[!0-9]/}
echo SBATCHID

# compute mean Modis fSCA
# echo "Process modis fsca"
# sbatch --dependency=singleton --job-name=da slurm_modis.sh
# echo "Done!"

SBATCHID=$(sbatch  --dependency=afterany:$jid6  slurm_modis.sh $1)
jid7=${SBATCHID//[!0-9]/}
echo SBATCHID

# run PBS and plots
# echo "run pbs"
# sbatch --dependency=singleton --job-name=modis slurm_pbs.sh  $1  $4
# echo "Done!"

SBATCHID=$(sbatch  --dependency=afterany:$jid7  slurm_pbs.sh  $1  $4)
jid8=${SBATCHID//[!0-9]/}
echo SBATCHID
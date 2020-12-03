# now can run from workdir ca save project specific version

# Example bash tmapp_hpc_points_run.sh /home/caduff/sim/ch_points_test/ 200 500 2017

# Args:
#	$1: is working directory
# 	$2: number of points (simdirs) rounded up to nearest 100
#	$3: number of months rounded up to nearest 100


# 	$4: data assimilation year corresponding to melt period

# variables
# number of era5 grids
NENSEMBLE=100 # must match config.ini
NJOBS=100 # can be any reasonable number
DA=true


if [[ $# -eq 0 ]] ; then
    echo 'Working directory needed as Arg1'
    exit 0
fi

cd /home/caduff/src/tmapp2
# clear logs
rm LOG*

source bin/activate
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

SBATCHID=$(sbatch slurm_setup_points.sh $1) # single array
jid1=${SBATCHID//[!0-9]/}

SBATCHID=$(sbatch  --dependency=afterany:$jid1 --array=1-$NJOBS  slurm_svf_points.sh $1 $2) # array of simdirs (points)
jid2=${SBATCHID//[!0-9]/}

# array = reasonable number
SBATCHID=$(sbatch  --dependency=afterany:$jid2 --array=1-$NJOBS slurm_tscale.sh $1 $3) # array of months
jid3=${SBATCHID//[!0-9]/}

SBATCHID=$(sbatch  --dependency=afterany:$jid3  --array=1-$NJOBS slurm_sim.sh $1 $3)
jid4=${SBATCHID//[!0-9]/}



if [ "$DA" = true ] ; then

	# DA doesnt need to wait for map jobs

	# Generate meteo purturbations 
	SBATCHID=$(sbatch  --dependency=afterany:$jid4  --array=1 slurm_perturb.sh $1)
	jid5=${SBATCHID//[!0-9]/}

	# run ensembles get results, array = number of ensembles (in config.ini)
	SBATCHID=$(sbatch  --dependency=afterany:$jid5  --array=1-$NENSEMBLE slurm_da.sh $1 $4)
	jid6=${SBATCHID//[!0-9]/}

	# compute mean Modis fSCA
	SBATCHID=$(sbatch  --dependency=afterany:$jid6 --array=1 slurm_modis.sh $1 $4)
	jid7=${SBATCHID//[!0-9]/}

	# run PBS and plots
	SBATCHID=$(sbatch  --dependency=afterany:$jid7 --array=1 slurm_pbs.sh  $1  $4)
	jid8=${SBATCHID//[!0-9]/}

	# map out ensemble with highest weight
	#SBATCHID=$(sbatch  --dependency=afterany:$jid11  --array=1 slurm_map.sh $1 ensemble $NGRIDS 2019-03-31 2019-03-31)
	#jid12=${SBATCHID//[!0-9]/}

	fi

squeue -u caduff
#!/bin/bash
# JobArray.sh
# $1 : wd
# $2 : number of grids

#SBATCH -J tmapp # A single job name for the array
#SBATCH -p node # Partition (required)
#SBATCH -A node # Account (required)
#SBATCH -q normal # QOS (required)
#SBATCH -n 1 # one cores
#SBATCH -t 01:00:00 # Running time of 2 days
#SBATCH --mem 4000 # Memory request of 4 GB
#SBATCH -o log_svf.out # Standard output - write the console output to the output folder %A= Job ID, %a = task or Step ID
#SBATCH -e log_svf.err # Standard error -write errors to the errors folder and
#SBATCH --array=1-$1 # create a array from 1to $2 which is number of grids
#SBATCH --mail-user=joelfiddes@gmail.com
#SBATCH --mail-type=ALL  # Send me some mails when jobs end or fail.

pwd; hostname; date


# parallel however many grids there are (NGRID)
python tmapp_hpc_svf.py $1 ${SLURM_ARRAY_TASK_ID}


date
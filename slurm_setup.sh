#!/bin/bash
# JobArray.sh
#
#SBATCH -J tmapp # A single job name for the array
#SBATCH -p node # Partition (required)
#SBATCH -A node # Account (required)
#SBATCH -q normal # QOS (required)
#SBATCH -n 1 # one cores
#SBATCH -t 01:00:00 # Running time of 2 days
#SBATCH --mem 4000 # Memory request of 4 GB
#SBATCH -o setup.out # Standard output - write the console output to the output folder %A= Job ID, %a = task or Step ID
#SBATCH -e setup.err # Standard error -write errors to the errors folder and
#SBATCH --array=1 # create a array from 1to16 and limit the concurrent runing task  to 50
#SBATCH --mail-user=joelfiddes@gmail.com
#SBATCH --mail-type=ALL  # Send me some mails when jobs end or fail.

pwd; hostname; date

# run sequentially
# $1 is wd
python tmapp_hpc_setup.py $1


date



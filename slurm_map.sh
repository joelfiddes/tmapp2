#!/bin/bash


# $1 :  wd
# $2 : mode
# $3 : start (of map period) optional format = '2003-05-01' 
# $4 : end  (of map period) optional format = '2003-05-30'

# mode:
# 	subperiod
# 	allperiod
# 	da
# 	timseries

#SBATCH -J map # A single job name for the array
#SBATCH -p node # Partition (required)
#SBATCH -A node # Account (required)
#SBATCH -q normal # QOS (required)
#SBATCH -n 1 # one cores
#SBATCH -t 01:00:00 # Running time of 2 days
#SBATCH --mem 4000 # Memory request of 4 GB
#SBATCH -o LOG_map.out # Standard output - write the console output to the output folder %A= Job ID, %a = task or Step ID
#SBATCH -e LOG_map.err # Standard error -write errors to the errors folder and
#SBATCH --array=1 #
#SBATCH --mail-user=joelfiddes@gmail.com
#SBATCH --mail-type=ALL  # Send me some mails when jobs end or fail.

pwd; hostname; date

# run sequentially
# $1 is wd
python tmapp_hpc_map.py $1 $2 $3 $4 $5


date

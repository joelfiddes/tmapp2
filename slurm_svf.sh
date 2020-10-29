#!/bin/bash
# JobArray.sh
#
#SBATCH -J tmapp # A single job name for the array
#SBATCH -p node # Partition (required)
#SBATCH -A node # Account (required)
#SBATCH -q normal # QOS (required)
#SBATCH -n 1 # one cores
#SBATCH -t 02:00:00 # Running time of 2 days
#SBATCH --mem 4000 # Memory request of 4 GB
#SBATCH -o output/myArray_%A_%a.out # Standard output - write the console output to the output folder %A= Job ID, %a = task or Step ID
#SBATCH -e error/myArray_%A_%a.err # Standard error -write errors to the errors folder and
#SBATCH --array=1-21%50 # create a array from 1to16 and limit the concurrent runing task  to 50
#SBATCH --mail-user=joelfiddes@gmail.com
#SBATCH --mail-type=ALL  # Send me some mails when jobs end or fail.

pwd; hostname; date


# parallel however many grids there are (NGRID)
python tmapp_hpc_svf.py wd

# parallelise through time (use NGRID as devidor)
# This is an example script that combines array tasks with
# bash loops to process many short runs. Array jobs are convenient
# for running lots of tasks, but if each task is short, they
# quickly become inefficient, taking more time to schedule than
# they spend doing any work and bogging down the scheduler for
# all users. 


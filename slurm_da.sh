#!/bin/bash
# JobArray.sh
#$1 : wd
#$2 : da year
#
# run python tmapp_hpc_perturb.py #WD once at cmdline THEN:

# run sbatch slurm_da.sh /home/caduff/sim/ch_tmapp_50

#SBATCH -J da # A single job name for the array
#SBATCH -p node # Partition (required)
#SBATCH -A node # Account (required)
#SBATCH -q normal # QOS (required)
#SBATCH -n 1 # one cores
#SBATCH -t 05:00:00 # Running time of 2 days
#SBATCH --mem 4000 # Memory request of 4 GB
#SBATCH -o LOG_da.out # Standard output - write the console output to the output folder %A= Job ID, %a = task or Step ID
#SBATCH -e LOG_da.err # Standard error -write errors to the errors folder and
#SBATCH --array=1-100 # this is number of ensembles (100)
#SBATCH --mail-user=joelfiddes@gmail.com
#SBATCH --mail-type=ALL  # Send me some mails when jobs end or fail.


pwd; hostname; date



# parallelise through time (use NGRID as devidor)
# This is an example script that combines array tasks with
# bash loops to process many short runs. Array jobs are convenient
# for running lots of tasks, but if each task is short, they
# quickly become inefficient, taking more time to schedule than
# they spend doing any work and bogging down the scheduler for
# all users. 


#Set the number of runs that each SLURM task should do


# Calculate the starting and ending values for this task based
# on the SLURM task and the number of runs per task.

# Print the task and run range
echo This is task $SLURM_ARRAY_TASK_ID, which will do Ensemble $SLURM_ARRAY_TASK_ID 

 #Do your stuff here
python tmapp_hpc_daRunEnsemble.py $1 $SLURM_ARRAY_TASK_ID $2

python tmapp_hpc_daGetResults.py $1 $2 $SLURM_ARRAY_TASK_ID 

date



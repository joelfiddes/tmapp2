#!/bin/bash
# JobArray.sh
#
# $1 : wd
# $2 : NMONTHS


#SBATCH -J tmapp # A single job name for the array
#SBATCH -p node # Partition (required)
#SBATCH -A node # Account (required)
#SBATCH -q normal # QOS (required)
#SBATCH -n 1 # one cores
#SBATCH -t 02:00:00 # Running time of 2 days
#SBATCH --mem 4000 # Memory request of 4 GB
#SBATCH -o output/myArray_%A_%a.out # Standard output - write the console output to the output folder %A= Job ID, %a = task or Step ID
#SBATCH -e error/myArray_%A_%a.err # Standard error -write errors to the errors folder and
#SBATCH --array=1-100 # create a array from 1to16 and limit the concurrent runing task  to 50
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
PER_TASK=$2/100

# Calculate the starting and ending values for this task based
# on the SLURM task and the number of runs per task.
START_NUM=$(( ($SLURM_ARRAY_TASK_ID - 1) * $PER_TASK + 1 ))
END_NUM=$(( $SLURM_ARRAY_TASK_ID * $PER_TASK ))

# Print the task and run range
echo This is task $SLURM_ARRAY_TASK_ID, which will do runs $START_NUM to $END_NUM

# Run the loop of runs for this task.
for (( run=$START_NUM; run<=END_NUM; run++ )); do
  echo This is SLURM task $SLURM_ARRAY_TASK_ID, run number $run
  #Do your stuff here
	python tmapp_hpc_tscale.py wd

done

date



# paralleise over sims (use NGRID as divifor)
# efficient running of many small taskshttps://help.rc.ufl.edu/doc/SLURM_Job_Arrays 
# eg As an example let's imaging I have 5,000 runs of a program to do, with each run taking about 30 seconds to complete. Rather than running an array job with 5,000 tasks, 
# it would be much more efficient to run 5 tasks where each completes 1,000 runs. Here's a sample script to accomplish this by combining array jobs with bash loops.
Python r_passingArguments.R input/input"${SLURM_ARRAY_TASK_ID}".txt    #R
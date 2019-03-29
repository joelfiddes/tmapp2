#!/bin/sh
#SBATCH -J tmapp
#SBATCH --mail-type=ALL
#SBATCH --mail-user=joelfiddes@gmail.com
#SBATCH --workdir=/home/caduff/src/tmapp2/
#SBATCH --ntasks=45       # tasks requested
#SBATCH --mem-per-cpu=4000
#SBATCH -o outfile  # send stdout to outfile
#SBATCH -e errfile  # send stderr to errfile
#SBATCH -t 7:00:00  # time requested in hour:minute:second


python slurm.py 45 /home/caduff/sim/ch


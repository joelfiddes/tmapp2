#!/bin/sh
#SBATCH -J tmapp
#SBATCH --mail-type=ALL
#SBATCH --mail-user=joelfiddes@gmail.com
#SBATCH --workdir=/home/caduff/src/tmapp2/
#SBATCH --ntasks=10	  # tasks requested
#SBATCH -o outfile  # send stdout to outfile
#SBATCH -e errfile  # send stderr to errfile
#SBATCH -t 2:00:00  # time requested in hour:minute:second


python slurm.py 10 /home/caduff/sim/test/


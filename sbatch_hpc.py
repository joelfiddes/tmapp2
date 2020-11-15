#!/usr/local/bin/python

# Example python sbatch_hpc.py /home/caduff/sim/ccamm_inter 100 1200 2003

# Args:
#	$1: is working directory
# 	$2: number of months in sim rounded up to nearest 100
# 	$3: number of samples rounded up to nearest 100
# 	$4: data assimilation year corresponding to melt period


import commands, os, sys

wd=sys.argv[1]
Nmonths=sys.argv[2]
Nsamples=sys.argv[3]
Dayear=sys.argv[3]

# submit the first job
cmd = "python tmapp_hpc_setup.py" + wd
print "Submitting Job1 with command: %s" % cmd
status, jobnum = commands.getstatusoutput(cmd)
if (status == 0 ):
    print "Job1 is %s" % jobnum
else:
    print "Error submitting Job1"


# submit the second job to be dependent on the first
cmd = "sbatch --depend=afterany:%s slurm_svf.sh" + wd % jobnum
print "Submitting Job2 with command: %s" % cmd
status,jobnum = commands.getstatusoutput(cmd)
if (status == 0 ):
    print "Job2 is %s" % jobnum
else:
    print "Error submitting Job2"

# submit the third job to be dependent on the second
cmd = "sbatch --depend=afterany:%s slurm_tscale.sh "+ wd+" "+Nmonths % jobnum
print "Submitting Job2 with command: %s" % cmd
status,jobnum = commands.getstatusoutput(cmd)
if (status == 0 ):
    print "Job2 is %s" % jobnum
else:
    print "Error submitting Job2"



print "\nCurrent status:\n"
#show the current status with 'sjobs'
os.system("sjobs")
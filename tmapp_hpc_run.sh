WD = '/home/caduff/sim//ch_tmapp_50/'

sbatch tmapp_hpc_run.sh $WD
sbatch tmapp_hpc_svf.sh $WD 21
sbatch slurm_tscale.sh $WD 500
sbatch slurm_sim.sh $WD 1100
python tmapp_hpc_perturb.py $WD

# number of ensembles declared in here
sbatch slurm_da.sh $WD

python tmapp_hpc_HX.py  $WD  2003
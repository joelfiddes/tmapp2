#!/bin/bash
python tmapp_setup.py /home/joel/sim/topomapptest/config.ini

# loop through or send to cluster
#python tmapp_run.py /home/joel/sim/topomapptest/ g1m1 1
python tmapp_run.py /home/joel/sim/topomapptest/ g1m2 2 &
python tmapp_run.py /home/joel/sim/topomapptest/ g1m3 3 &
python tmapp_run.py /home/joel/sim/topomapptest/ g1m4 4 &
python tmapp_run.py /home/joel/sim/topomapptest/ g1m5 5 &
python tmapp_run.py /home/joel/sim/topomapptest/ g1m6 6 &
python tmapp_run.py /home/joel/sim/topomapptest/ g1m7 7 &
python tmapp_run.py /home/joel/sim/topomapptest/ g1m8 8 & 
python tmapp_run.py /home/joel/sim/topomapptest/ g1m9 9 &
python tmapp_run.py /home/joel/sim/topomapptest/ g1m10 10 &

parallel  -eta python tmapp_run.py ::: /home/joel/sim/topomapptest/ ::: g1m3 g1m5 g1m6 g1m7 g1m8 g1m9 g1m10 ::: 3 5 6 7 8 9 10

#!/bin/bash
python tmapp_setup.py /home/joel/sim/topomapptest/config.ini

# loop through or send to cluster
python tmapp_run.py /home/joel/sim/topomapptest/ g1m1 1
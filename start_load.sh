#!/bin/bash

./run_load.sh 9090 1 &
./run_load.sh 9100 2 &
./run_load.sh 9110 3 &
./run_load.sh 9120 4 &
./run_load.sh 9130 5 &
./run_load.sh 9140 6 &
./run_load.sh 9150 7 &
./run_load.sh 9160 8 &
./run_load.sh 9170 9 &
./run_load.sh 9180 10 &

sleep 30s

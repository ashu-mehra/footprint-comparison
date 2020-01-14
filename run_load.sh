#!/bin/bash

if [ $# -ne 4 ]; then
	echo "$0: Insufficient arguments; need port number and output file"
	exit
fi
port=$1
index=$2
pid=$3
is_native=$4

if [ "${is_native}" -eq "0" ]; then
	command="java"
else
	command="application"
fi

for USERS in 1 5 10 15 20 25 30 35 40
do
	echo "Runnning with $USERS users"
	for run in {1..2}
	do
		top_pid=""
		if [ "${run}" -eq "2" ]; then
			./run_top.sh "${pid}" &> top.${index}.${USERS}.out &
			sleep 1s
			top_pid=`ps -ef | grep "top -b" | grep -v grep | awk '{ print $2 }'`
		fi

		numactl --physcpubind="24-31" --membind="1" ./wrk --threads=$USERS --connections=$USERS -d60s http://127.0.0.1:${port}/fruits &>tput.${index}.${USERS}.${run}.out

		if [ "${run}" -eq "2" ]; then
			kill -9 ${top_pid}
			grep "${pid}" top.${index}.${USERS}.out | grep ${command} | awk '{ print $6 }' &> memory.${index}.${USERS}.out
			max_mem=`cat memory.${index}.${USERS}.out | sort -rn | head -n 1`
			echo "Peak Memory: ${max_mem} KB" >> memory.${index}.${USERS}.out
			grep "${pid}" top.${index}.${USERS}.out | grep ${command} | awk '{ print $9 }' &> cpu.${index}.${USERS}.out
			avg_cpu=`awk 'BEGIN{sum=0}{sum += $1}END{print sum/NR}' cpu.${index}.${USERS}.out`
			echo "Avg CPU: ${avg_cpu}" >> cpu.${index}.${USERS}.out
		fi
	done
done


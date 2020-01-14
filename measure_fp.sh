#!/bin/bash

FOOTPRINT_ANALYSIS="/home/ashutosh/FootprintAnalysis/FootprintAnalysis/footprintAnalysis.linux"

if [ $# -ne 4 ]; then
	echo "Insufficient arguments"
	exit
fi

log_dir_prefix=$1
instance=$2
RESULTS_DIR=$3
is_native=$4

logs_dir="${RESULTS_DIR}/${log_dir_prefix}-${instance}"
echo "Running footprint analysis for directory ${logs_dir}"
if [ "${is_native}" -eq "0" ]; then
	# ${FOOTPRINT_ANALYSIS} -s ${logs_dir}/smaps -j ${logs_dir}/javacore.txt -p ${logs_dir}/mypagemap -c ${logs_dir}/allcallsites.txt -m ${logs_dir}/active_malloc.txt -a ${logs_dir}/active_allocations.txt &> ${logs_dir}/fp.txt
	${FOOTPRINT_ANALYSIS} -s ${logs_dir}/smaps -j ${logs_dir}/javacore.txt -p ${logs_dir}/mypagemap -c ${logs_dir}/allcallsites.txt -a ${logs_dir}/active_allocations.txt &> ${logs_dir}/fp.txt
	${FOOTPRINT_ANALYSIS} -s ${logs_dir}/smaps -j ${logs_dir}/javacore.txt -p ${logs_dir}/mypagemap -c ${logs_dir}/allcallsites.txt &> ${logs_dir}/fp_orig.txt
else
	${FOOTPRINT_ANALYSIS} -s ${logs_dir}/smaps -p ${logs_dir}/mypagemap -a ${logs_dir}/active_allocations.txt &> ${logs_dir}/fp.txt
fi


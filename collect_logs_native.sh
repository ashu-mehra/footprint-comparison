#!/bin/bash

run()
{
	echo "CMD: $@"
	$@
}

PID_JAVA="1" # 1 is the pid of the java process in the container

if [ $# -ne 3 ]; then
	echo "Insufficient arguments"
	exit
fi

CONTAINER_NAME_PREFIX=$1
instance=$2
RESULTS_DIR=$3

container="${CONTAINER_NAME_PREFIX}-${instance}" 
echo "Collecting logs for container ${container}"
logs_dir="${RESULTS_DIR}/${CONTAINER_NAME_PREFIX}-${instance}"
rm -fr ${logs_dir}
mkdir -p ${logs_dir}

basedir=`pwd`
pushd ${logs_dir}

echo "Collecting allocations trace file"
cmd="docker cp ${container}:/work/alloc_trace.txt ." 
run ${cmd}
cmd="docker cp ${container}:/work/mmap_trace.txt ."
run ${cmd}

echo "Collecting smaps file"
pid_on_host=`docker top ${container} | grep application | awk '{ print $2 }'`
echo "pid on host: ${pid_on_host}"
cp /proc/${pid_on_host}/smaps .
pmap -X ${pid_on_host} > pmap.out

echo "Collecting pagemap info"
/home/ashutosh/FootprintAnalysis/FootprintAnalysis/createpagemap smaps ${pid_on_host} &> createpagemap.log
mv mypagemap .

echo "Collecting active allocations"
/home/ashutosh/memory_tracker/active_allocations alloc_trace.txt active_allocations.txt &> active.log
/home/ashutosh/memory_tracker/active_allocations mmap_trace.txt active_mmap.txt &> active_mmap.log
/home/ashutosh/memory_tracker/mmapmatch.sh

mv ${basedir}/tput.*out .
mv ${basedir}/top.*out .
mv ${basedir}/memory.*out .
mv ${basedir}/cpu.*out .

popd

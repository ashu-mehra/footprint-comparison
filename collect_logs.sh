#!/bin/bash

run()
{
	echo "CMD: $@"
	$@
}

JDMPVIEW="/home/ashutosh/builds/openj9/jdk8u232-b09/bin/jdmpview"

if [ $# -ne 3 ]; then
	echo "$0: Insufficient arguments"
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

echo "Collecting allocations trace files"
#cmd="docker cp ${container}:/work/malloc_trace.txt ."
#run ${cmd}
cmd="docker cp ${container}:/work/alloc_trace.txt ."
run ${cmd}
cmd="docker cp ${container}:/work/mmap_trace.txt ."
run ${cmd}

echo "Collecting smaps file"
pid_on_host=`docker top ${container} | grep java | awk '{ print $2 }'`
echo "pid on host: ${pid_on_host}"
cp /proc/${pid_on_host}/smaps . 
pmap -X ${pid_on_host} > pmap.out

echo "Collecting pagemap info"
/home/ashutosh/FootprintAnalysis/FootprintAnalysis/createpagemap smaps ${pid_on_host} &> createpagemap.log

echo "Collecting active allocations"
#mtrace malloc_trace.txt &> malloc_trace_format.txt
#startLine=`grep -n "Memory not freed" malloc_trace_format.txt | cut -d ':' -f 1`
#startLine=$(( $startLine+3 ))
#tail -n +${startLine} malloc_trace_format.txt > active_malloc.txt
/home/ashutosh/memory_tracker/active_allocations alloc_trace.txt active_allocations.txt &> active_allocations.log
/home/ashutosh/memory_tracker/active_allocations mmap_trace.txt active_mmap.txt &> active_mmap.log
/home/ashutosh/memory_tracker/mmapmatch.sh

echo "Collecting javacore and coredump from container"
pid_container=`docker exec ${container} ps -ef | grep java | grep -v grep | awk '{ print $2 }'`
cmd="docker exec ${container} kill -3 ${pid_container}"
run ${cmd}

echo "Collecting gc logs"
cmd="docker cp ${container}:/tmp/gc.log ."
run ${cmd}

echo "Collecting jit logs"
jitlog=`docker exec ${container} ls /tmp | grep jit.log`
cmd="docker cp ${container}:/tmp/${jitlog} ."
run ${cmd}

while true;
do
	sleep 1s
	docker exec ${container} bash -c "ls /tmp/core*"
	if [ $? -eq 0 ]; then
		docker exec ${container} bash -c "ls /tmp/javacore*"
		if [ $? -eq 0 ]; then
			break
		fi
	fi
done
cmd="docker cp ${container}:/tmp/core.dmp ."
run ${cmd}
cmd="docker cp ${container}:/tmp/javacore.txt ."
run ${cmd}

echo "Collecting callsite info"
${JDMPVIEW} -cmdfile ${basedir}/printallcallsites.txt -outfile allcallsites.txt -core core.dmp &> /dev/null

mv ${basedir}/tput.*out .
mv ${basedir}/top.*out .
mv ${basedir}/memory.*out .
mv ${basedir}/cpu.*out .

cmd="docker cp ${container}:/tmp/app.out ."
run ${cmd}

popd

#!/bin/bash

DOCKER_CAPABILITIES="--cap-add AUDIT_CONTROL --cap-add DAC_READ_SEARCH --cap-add NET_ADMIN --cap-add SYS_ADMIN --cap-add SYS_PTRACE --cap-add SYS_RESOURCE"
DOCKER_SECURITY_OPTS="--security-opt apparmor=unconfined --security-opt seccomp=unconfined"

DB_CONTAINER_NAME_PREFIX="postgres-quarkus-rest-http-crud"
CONTAINER_NAME_PREFIX="rest-crud"
CONTAINER_IMAGE="rest-crud-quarkus-native"

run()
{
	echo "CMD: $@"
	$@
}

running_native_image()
{
	if [[ "${CONTAINER_IMAGE}" =~ .*"native".* ]]; then
		echo 1
	else
		echo 0
	fi
}

start_db()
{
	dbindex=$1
	db_port=$(( ${dbindex} * 10 + 5432 ))
	docker run -d --cpuset-cpus=0-15 --cpuset-mems=1  --ulimit memlock=-1:-1 -it --rm=true --memory-swappiness=0 --name ${DB_CONTAINER_NAME_PREFIX}-${dbindex} -e POSTGRES_USER=restcrud -e POSTGRES_PASSWORD=restcrud -e POSTGRES_DB=rest-crud -p ${db_port}:5432 postgres:10.5
}

start_app()
{
	echo "Starting instance $1"
	instance=$1
	host_port=$(( ${instance} * 10 + 9080 ))
	dbindex=$2
	db_port=$(( ${dbindex} * 10 + 5432 ))
	echo "Using port ${host_port}"
	native_image_heap_settings="-Xms75m -Xmn86m -Xmx96m"

	# for liberty
	# cmd="docker run --rm --cpuset-cpus=0,1,32,33 --cpuset-mems=0 --name="${CONTAINER_NAME_PREFIX}-${instance}" --env-file=java.env "${DOCKER_CAPABILITIES}" "${DOCKER_SECURITY_OPTS}" -d -p ${host_port}:9080 "${CONTAINER_IMAGE}""

	# for quarkus-pingperf-jvm
	# cmd="docker run --rm --cpuset-cpus=0,1,32,33 --cpuset-mems=0 --name="${CONTAINER_NAME_PREFIX}-${instance}" --env-file=java.env -d -p ${host_port}:8080 "${CONTAINER_IMAGE}""

	# for quarkus-pingperf-native
	# cmd="docker run --rm --cpuset-cpus=0,1,32,33 --cpuset-mems=0 --name="${CONTAINER_NAME_PREFIX}-${instance}" -d -p ${host_port}:8080 "${CONTAINER_IMAGE}""

	# for quarkus-rest-crud-jvm
	# cmd="docker run --rm --cpuset-cpus=0,1,32,33 --cpuset-mems=0 --name="${CONTAINER_NAME_PREFIX}-${instance}" --network host --init --env-file=java.env -d --env HTTP_PORT=${host_port} --env DB_PORT=${db_port} "${CONTAINER_IMAGE}""
	# cmd="docker run --rm --cpuset-cpus=0-15 --cpuset-mems=0 --name="${CONTAINER_NAME_PREFIX}-${instance}" --network host --init --env-file=java.env -d --env HTTP_PORT=${host_port} --env DB_PORT=${db_port} "${CONTAINER_IMAGE}""
	cmd="docker run --rm --name="${CONTAINER_NAME_PREFIX}-${instance}" --network host --init --env-file=java.env -d --env HTTP_PORT=${host_port} --env DB_PORT=${db_port} "${CONTAINER_IMAGE}""

	# for quarkus-rest-crud-native
	# cmd="docker run --rm --cpuset-cpus=0,1,32,33 --cpuset-mems=0 --network host --name="${CONTAINER_NAME_PREFIX}-${instance}" --init -d --env HTTP_PORT=${host_port} --env DB_PORT=${db_port} "${CONTAINER_IMAGE}""
	# cmd="docker run --rm --network host --name="${CONTAINER_NAME_PREFIX}-${instance}" --init -d --env-file=nativeimage.env --env HTTP_PORT=${host_port} --env DB_PORT=${db_port} "${CONTAINER_IMAGE}""
	cmd="docker run --rm --cpuset-cpus=0-15,32-47 --cpuset-mems=0 --network host --name="${CONTAINER_NAME_PREFIX}-${instance}" --init -d --env-file=nativeimage.env --env HTTP_PORT=${host_port} --env DB_PORT=${db_port} "${CONTAINER_IMAGE}""

	# for helloworld
	#cmd="docker run --rm --cpuset-cpus=0,1,32,33 --cpuset-mems=0 --name="${CONTAINER_NAME_PREFIX}-${instance}" --init --env-file=java.env -d "${CONTAINER_IMAGE}""

	echo "CMD: ${cmd}"
	containerid=`${cmd}`
	echo "Container id: ${containerid}"
}

summarize_results()
{
	if [ "${is_native}" -eq "0" ]; then
		rm -f oneline.summary
		rm -f breakup.summary
		for i in `seq 1 ${instances}`;
		do
			grep "Totals" ${RESULTS_DIR}/${CONTAINER_NAME_PREFIX}-${i}/fp.txt >> ${RESULTS_DIR}/oneline.summary
			grep -A 16 "Totals" ${RESULTS_DIR}/${CONTAINER_NAME_PREFIX}-${i}/fp.txt >> ${RESULTS_DIR}/breakup.summary
		done

		total_rss=`awk 'BEGIN { sum = 0 }{ sum=sum+$6 } END{ print sum }' ${RESULTS_DIR}/oneline.summary`
		total_pss=`awk 'BEGIN { sum = 0 }{ sum=sum+$9 } END{ print sum }' ${RESULTS_DIR}/oneline.summary`
		total_savings=$(( ${total_rss} - ${total_pss} ))
		avg_rss=$(( ${total_rss}/${instances} ))
		avg_pss=$(( ${total_pss}/${instances} ))
		avg_savings=$(( ${total_savings}/${instances} ))

		echo "" >> ${RESULTS_DIR}/oneline.summary
		echo "Total RSS: ${total_rss} KB" >> ${RESULTS_DIR}/oneline.summary
		echo "Total PSS: ${total_pss} KB">> ${RESULTS_DIR}/oneline.summary
		echo "Total Savings: ${total_savings} KB" >> ${RESULTS_DIR}/oneline.summary
		echo "" >> ${RESULTS_DIR}/oneline.summary
		echo "Avg RSS: ${avg_rss} KB" >> ${RESULTS_DIR}/oneline.summary
		echo "Avg PSS: ${avg_pss} KB">> ${RESULTS_DIR}/oneline.summary
		echo "Avg Savings: ${avg_savings} KB" >> ${RESULTS_DIR}/oneline.summary
	fi

	for i in `seq 1 ${instances}`;
	do
		tail -n 1 ${RESULTS_DIR}/${CONTAINER_NAME_PREFIX}-${i}/pmap.out | awk '{ print "RSS: ",$2, " PSS: ",$3 }' >> ${RESULTS_DIR}/pmap.summary
	done

	total_rss=`awk 'BEGIN { sum = 0 }{ sum=sum+$2 } END{ print sum }' ${RESULTS_DIR}/pmap.summary`
	total_pss=`awk 'BEGIN { sum = 0 }{ sum=sum+$4 } END{ print sum }' ${RESULTS_DIR}/pmap.summary`
	total_savings=$(( ${total_rss} - ${total_pss} ))
	avg_rss=$(( ${total_rss}/${instances} ))
	avg_pss=$(( ${total_pss}/${instances} ))
	avg_savings=$(( ${total_savings}/${instances} ))

	echo "" >> ${RESULTS_DIR}/pmap.summary
	echo "Total RSS: ${total_rss} KB" >> ${RESULTS_DIR}/pmap.summary
	echo "Total PSS: ${total_pss} KB">> ${RESULTS_DIR}/pmap.summary
	echo "Total Savings: ${total_savings} KB" >> ${RESULTS_DIR}/pmap.summary
	echo "" >> ${RESULTS_DIR}/pmap.summary
	echo "Avg RSS: ${avg_rss} KB" >> ${RESULTS_DIR}/pmap.summary
	echo "Avg PSS: ${avg_pss} KB">> ${RESULTS_DIR}/pmap.summary
	echo "Avg Savings: ${avg_savings} KB" >> ${RESULTS_DIR}/pmap.summary
}

if [ $# -lt 1 ]; then
	echo "Insufficient arguments"
	exit 1
fi

instances=$1

if [ $# -eq 2 ]; then
	RESULTS_DIR=$2
else
	RESULTS_DIR="results"
fi

rm -fr ${RESULTS_DIR}
mkdir -p ${RESULTS_DIR}

echo "Running with ${instances} instances"
echo "Results directory is ${RESULTS_DIR}"

is_native=$(running_native_image)
echo "is_native: ${is_native}"

db_index=0;
for index in `seq 1 ${instances}`;
do
	if [ $((${index} % 4)) -eq "1" ]; then
		db_index=$(($db_index + 1))
		echo "Starting db instance ${db_index}"
		start_db ${db_index}
		sleep 10s
	fi

	start_app ${index} ${db_index}
done

sleep 10s # allow all apps to be up and running

<< COMMENT
port_list=""
for index in `seq 1 ${instances}`;
do
	port_list="${port_list} $(( ${index} * 10 + 9080 ))"
done

echo "ports to use for load: ${port_list}"
parallel ./run_load.sh ::: ${port_list}
COMMENT

for index in `seq 1 ${instances}`;
do
	port=$(( ${index} * 10 + 9080 ))

	if [ "${is_native}" -eq "0" ]; then
		command="java"
	else
		command="application"
	fi

	container="${CONTAINER_NAME_PREFIX}-${index}"
	pid_on_host=`docker top ${container} | grep ${command} | awk '{ print $2 }'`
	echo "pid on host: ${pid_on_host}"

	./run_load.sh ${port} "${index}" "${pid_on_host}" "${is_native}"

done

sleep 5s

for index in `seq 1 ${instances}`;
do
	if [ "${is_native}" -eq "1" ]; then
		./collect_logs_native.sh "${CONTAINER_NAME_PREFIX}" "${index}" "${RESULTS_DIR}"
	else
		./collect_logs.sh "${CONTAINER_NAME_PREFIX}" "${index}" "${RESULTS_DIR}"
	fi
done
# parallel ./collect_logs.sh ::: ${CONTAINER_NAME_PREFIX} ::: `seq 1 ${instances}` ::: ${RESULTS_DIR}
for index in `seq 1 ${instances}`;
do
	./measure_fp.sh ${CONTAINER_NAME_PREFIX} ${index} ${RESULTS_DIR} ${is_native}
	echo
done
# parallel ./measure_fp.sh ::: ${CONTAINER_NAME_PREFIX} ::: `seq 1 ${instances}` ::: ${RESULTS_DIR} ::: ${is_native}
summarize_results

list=""
for index in `seq 1 ${instances}`;
do
	list="${list} ${CONTAINER_NAME_PREFIX}-${index}"
done

cmd="docker stop ${list}" 
run ${cmd}

list=""
for index in `seq 1 ${db_index}`;
do
	list="${list} ${DB_CONTAINER_NAME_PREFIX}-${index}"
done

cmd="docker stop ${list}" 
run ${cmd}

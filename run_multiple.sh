#!/bin/bash

./run.sh 10 openj9/xms_xmx_128m_thpalways_nocpus/10
sleep 5s
sed -i 's/Xms128m/Xms64m/' java.env
sed -i 's/Xmx128m/Xmx64m/' java.env
./run.sh 10 openj9/xms_xmx_64m_thpalways_nocpus/10
sleep 5s
sed -i 's/Xms64m/Xms32m/' java.env
sed -i 's/Xmx64m/Xmx32m/' java.env
./run.sh 10 openj9/xms_xmx_32m_thpalways_nocpus/10
sleep 5s
sed -i 's/Xms32m/Xms28m/' java.env
sed -i 's/Xmx32m/Xmx28m/' java.env
./run.sh 10 openj9/xms_xmx_28m_thpalways_nocpus/10
sleep 5s
sed -i 's/Xms28m/Xms24m/' java.env
sed -i 's/Xmx28m/Xmx24m/' java.env
./run.sh 10 openj9/xms_xmx_24m_thpalways_nocpus/10
sleep 5s
sed -i 's/Xms24m/Xms20m/' java.env
sed -i 's/Xmx24m/Xmx20m/' java.env
./run.sh 10 openj9/xms_xmx_20m_thpalways_nocpus/10
sleep 5s
sed -i 's/Xms20m/Xms18m/' java.env
sed -i 's/Xmx20m/Xmx18m/' java.env
./run.sh 10 openj9/xms_xmx_18m_thpalways_nocpus/10
sleep 5s

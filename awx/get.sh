#!/bin/bash

set -e

AWX="192.168.56.23:30964"
CRED="hs:hs"
#PL="p_configure_linux.yml"
PL="awx/p_fast.yaml"
OUT="./out"

clear && mkdir -p ${OUT}

echo -e "Get TemplateID"
ID=$(curl -k -s --user ${CRED} -X GET -H "Content-Type: application/json" \
	"http://${AWX}/api/v2/job_templates/" \
	--data '{}'| jq '.results[]| select(.playbook=='\"${PL}\"')|.id') 
echo -e "\t-> ${ID}\n\n"

echo -e "Launch Template and get JOBID"
JOB=$(curl -k -s --user ${CRED} -X POST -H "Content-Type: application/json" \
        "http://${AWX}/api/v2/job_templates/${ID}/launch/" \
        --data '{}'|jq '.job') 
echo -e "\t-> ${JOB}\n\n"


echo -e "Launched: ..."

STATUS=""
FAILED=""

while [ "${STATUS}" != "successful" ] 
do
	STATUS=$(curl -k -s --user ${CRED} -X GET -H "Content-Type: application/json" \
        	"http://${AWX}/api/v2/jobs/${JOB}/" | jq '.status'|sed -e 's/"//g')
	FAILED=$(curl -k -s --user ${CRED} -X GET -H "Content-Type: application/json" \
        	"http://${AWX}/api/v2/jobs/${JOB}/" | jq '.failed')

	GET_FROM_ANSIBLE=$(curl -k -s --user ${CRED} -X GET -H "Content-Type: application/json" \
                "http://${AWX}/api/v2/jobs/${JOB}/" | jq '.artifacts')

	[ "${GET_FROM_ANSIBLE}" != "{}" ] && echo -e "\n\nReturn:\n${GET_FROM_ANSIBLE}\n\n"

done

echo -e  "\t-> ${JOB}\t${ID}\t${STATUS}\t${FAILED}"

curl -k -s --user ${CRED} -X GET -H "Content-Type: application/json" \
                "http://${AWX}/api/v2/jobs/${JOB}/" > ${OUT}/job_info.job_${ID}_${JOB}

curl -k -s --user ${CRED} -X GET -H "Content-Type: application/json" \
        "http://${AWX}/api/v2/jobs/${JOB}/stdout/?format=txt" > ${OUT}/stdout.job_${ID}_${JOB}  


echo -e "Wrote Logs: ${OUT}/job_info.job_${ID}_${JOB}, stdout.job_${ID}_${JOB}\n\n"

#!/bin/bash

DEVICE=$1
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-docker}
OUTPUT_DIR=${OUTPUT_DIR:-/tmp/output-fio}
mkdir -p ${OUTPUT_DIR}
rm -rf ${OUTPUT_DIR}/*

if [ -z "$DEVICE" ]; then
	echo "Provide the device to test as first argument"
	exit 0
fi 

${CONTAINER_RUNTIME} run --security-opt label=disable -ti \
	-v ${OUTPUT_DIR}:/output \
	--privileged \
	-w /output \
	-v ${DEVICE}:/dev/device-to-test \
	fio \
	fio /fio-jobs/*.fio --output fio.log


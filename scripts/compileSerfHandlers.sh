#!/bin/bash

# Run this from root of the repo

## utility Function
output_file_name() {
	filename=$1
	echo `echo $filename | grep  "\.go" | awk -F"/" '{ print $NF}' | sed 's/.go//g'`
}

echo "Compile Event Handlers"
HANDLERS_SRC_PATH=serf/handlers/src
HANDLERS_BIN_PATH=serf/handlers/bin
files=`ls ${HANDLERS_SRC_PATH}/*.go | grep -v test`
for input_file in $files
do
	output=`output_file_name $input_file`
	echo "Compile $input_file to ${HANDLERS_BIN_PATH}/$output"
	go build -o ${HANDLERS_BIN_PATH}/$output $input_file
done

echo "Compile Query Handlers"
QUERY_BIN_PATH=serf/handlers/bin
QUERY_SRC_PATH=serf/handlers/src/query
files=`ls ${QUERY_SRC_PATH}/*.go | grep -v test`
for input_file in $files
do
	output=`output_file_name $input_file`
	echo "Compile $input_file to ${QUERY_BIN_PATH}/$output"
	go build -o ${QUERY_BIN_PATH}/$output $input_file
done

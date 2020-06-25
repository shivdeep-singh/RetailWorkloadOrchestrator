#!/bin/bash
# This fiile should be run from RWO root folder or scripts folder
# Eg:
# 	bash scripts/buildSerfHandlers.sh
#   				or
#   cd scripts && ./buildSerfHandlers.sh
#
# During development or debugging, we don't want to pull packages again and again
# so, we can use this command to keep the packages persistent
#   bash scripts/buildSerfHandlers.sh debug

red=`tput setaf 1`
green=`tput setaf 2`
blue=`tput setaf 4`
C_RED='\e[31m'
C_GREEN='\e[32m'
T_RESET='\e[0m'
T_BOLD='\e[1m'

PWD=`pwd`
echo "Build started $PWD"

T_ERR_ICON="[${T_BOLD}${C_RED}✗${T_RESET}]"
T_OK_ICON="[${T_BOLD}${C_GREEN}✓${T_RESET}]"

# Update serf path
if  [[ -e .git ]]; then
  SERF_PATH=${PWD}/serf/handlers
else
# if run from inside scripts folder
  SERF_PATH=${PWD}/../serf/handlers
fi

build_status_accumulated=0
lint_status_accumulated=0

compile_updateconf() {
        echo "Compile updateconf.go"
        docker run --rm -e "GOPATH=/data/" -v ${SERF_PATH}/../../gluster:/data/src cytopia/golint -set_exit_status /data/src/updateconf.go
        docker run --rm -e "CGO_ENABLED=0" -v ${SERF_PATH}/../../gluster:/data/src golang:1.14.0 go build -a -installsuffix cgo -o /data/src/updateconf /data/src/updateconf.go
}

lint_handlers() {
	file=$1
    # Check $i is a file
    file_in_src=`echo $file | awk -F"src/" '{ print $2}'`

    if [ -f ${file} ]; then


        docker run --rm -e "GOPATH=/data/" -v ${SERF_PATH}:/data cytopia/golint -set_exit_status /data/src/${file_in_src}
        lint_status=$?

        if [ $lint_status -gt 0 ]; then
            echo -e " Lint ${T_ERR_ICON} ${T_RESET}"
        else
            echo -e " Lint ${T_OK_ICON} ${T_RESET}"
        fi

        lint_status_accumulated=`expr $lint_status + $lint_status_accumulated`
    fi
}


if [ ! -z $http_proxy ]; then
        PROXY_ARGS="--env \"http_proxy=$http_proxy\" -e \"https_proxy=$http_proxy\""
else
        PROXY_ARGS=""
fi

echo -e  "${C_GREEN}Begin Compilation ${T_RESET} "
compile_updateconf

# Lint the handler source files
for i in `ls ${SERF_PATH}/src/*.go | grep -v test`
do
    echo "$i"  | awk -F"zeroConf/" '{ print $2}'
    lint_handlers $i
#    compile_handlers $i
done

# Lint the handler source files
for i in `ls ${SERF_PATH}/src/query/*.go`
do
    echo "$i" | awk -F"zeroConf/" '{ print $2}'
    lint_handlers $i
done

# lint helpers source files
for i in `ls ${SERF_PATH}/src/helpers/*.go`
do
    echo "$i" | awk -F"zeroConf/" '{ print $2}'
    lint_handlers $i
done

# lint member-update-x source files
for i in `ls ${SERF_PATH}/src/memberupdatex/*.go`
do
    echo "$i" | awk -F"zeroConf/" '{ print $2}'
    lint_handlers $i
done

# Compile handlers
echo "${C_GREEN}Compile Handlers${T_RESET}"
docker run --rm   -e "CGO_ENABLED=0"  -v $(pwd):/data ${PROXY_ARGS} -t golang:1.14.0 bash -c "cd /data &&  scripts/compileSerfHandlers.sh"

## Check for linting problem and report error

if [ $lint_status_accumulated -gt 0 ]; then
    echo "${red} Lint Status "${lint_status_accumulated}
    echo "${red} Build Status "${build_status_accumulated}

	exit 1
fi


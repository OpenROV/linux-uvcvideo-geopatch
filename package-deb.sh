#!/bin/bash

#Set bash vars. 
# -e: Exit immediately if a command exits with a non-zero status.
# -x: Print commands and their arguments as they are executed.
set -ex

#Check if we need updates
#Returns true if there are
function need_to_update() {

  IFS=';' read updates security_updates < <(/usr/lib/update-notifier/apt-check 2>&1)
  if (( updates == 0 )); then
    echo "No updates are available"
  else
    echo "There are updates available"
  fi
}
#Array containing all of the packages we need from aptitude
declare -ar PRE_REQ_PROGRAMS=("ruby-dev" "ruby" "openssl")

#Function to install all of the pre req programs
function install_pre_req () {
  apt-get update

  #Aptitude pre reqs
  apt-get install --assume-yes ${PRE_REQ_PROGRAMS[@]}


  #Install fpm using ruby gem
  #First, check if it is already installed to save build time
  if `gem list fpm -i`
  then
    echo "FPM is already installed"
  else
    gem install fpm
  fi

}

#Directory operations
function create_directory() {

  #Make sure we got an actual string
  if [ -z "$1" ]
  then
    echo "No agrument passed to create_directory()"
  fi

  #Check if directory exists
  if [ -d "$1" ]
  then
    echo "$1 already exists."
  else
    mkdir $1
  fi
}

#Main output directory
declare -r OUTPUT_DIR="output"
create_directory output

#Set the machine hardware name
declare ARCH=`uname -m`
if [ ${ARCH} = "armv7l" ]
then
  ARCH="armhf"
fi

#Set the current directory name
declare -r DIR=${PWD#}

#Set the package version
declare -r PACKAGE_VERSION=1.0.0-1~${BUILD_NUMBER}.`git rev-parse --short HEAD`

#File containing the list of kernels we are going to build for and where to find them
declare -r LIST_OF_KERNELS="kernels.txt"

function build_package() {

  #Make sure we got an actual string
  if [ -z "$1" ]
  then
    echo "No string provided to build_package()!"
    exit 1
  fi

  #Make sure that it is a valid kernel string  
  IFS=',' read -a kernel_string <<< "$1"
  local kernel_version=${kernel_string[0]}
  local kernel_location=${kernel_string[1]}

  if ! [[ "$kernel_version" == 4.* ]]
  then
    echo "INVALID KERNEL VERSION"
    echo "BUILD ONLY SUPPORTS 4.x kernels on Debian Jessie"
    exit 1
  fi

  #If that is all good, create a directory for it
  local full_dir_string="./output/$kernel_version"
  create_directory $full_dir_string

  #./build.sh $kernel_version $kernel_location
}

function create_package() {

  #Make sure we got an actual string
  if [ -z "$1" ]
  then
    echo "No string provided to create_package()!"
    exit 1
  fi

  #Make sure that it is a valid kernel string
  local kernel_string=(${1//;})
  local kernel_version=${kernel_string[0]}
  local kernel_location=${kernel_string[1]}

  if ! [[ "$kernel_version" == 4.* ]]
  then
    echo "INVALID KERNEL VERSION"
    echo "BUILD ONLY SUPPORTS 4.x kernels on Debian Jessie"
    exit 1
  fi

  #If that is all good, call the fpm packager
  local package_name="linux-${kernel_version}-uvcvideo-geopatch"

  fpm -f -m info@openrov.com -s dir -t deb -a $ARCH \
  -n ${package_name} \
  -v ${PACKAGE_VERSION} \
  --after-install=${DIR}/install_lib/afterinstall.sh \
  --description "uvcvideo-geopatch" \
  -C ${DIR}/output .
}

#Main entry point of the bash script
function main() {
  install_pre_req

  #Iterate through kernels listed in the kernel file
  while read line
  do
    
    build_package $line    
  
  done < $LIST_OF_KERNELS
}

#Call the main script with args
main "$@"

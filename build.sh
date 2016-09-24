#!/bin/bash

#Set bash vars. 
# -e: Exit immediately if a command exits with a non-zero status.
# -x: Print commands and their arguments as they are executed.
set -e

#Error script that prints the correct usage of the build script
function print_usage() {
  echo "USAGE: ./build.sh [KERNEL_VERSION];[KERNEL_LOCATION]"
  echo "EXAMPLE: ./build.sh 4.1.22-ti-r59;http://repos.rcn-ee.com/debian/pool/main/l/linux-upstream/linux-headers-4.1.22-ti-r59_1jessie_armhf.deb"
  echo "Or, you can run with default parameters by using the following command:"
  echo "./build.sh -d"
  exit 1
}

#Global script variables
declare -r DEFAULT_FLAG="-d"
declare KERNEL_VERSION="4.1.22-ti-r59"
declare KERNEL_LOCATION="http://repos.rcn-ee.com/debian/pool/main/l/linux-upstream/linux-headers-4.1.22-ti-r59_1jessie_armhf.deb"

# # Build uvcvideo Kernel Driver for 4.1.x based Kernels
# make -j8 -C ./uvcvideo/uvc-4.1.1/

# mkdir -p ./output/lib/modules/${KERNEL_VERSION}/updates
# cp ./uvcvideo/uvc-4.1.1/uvcvideo.ko ./output/lib/modules/${KERNEL_VERSION}/updates


function main() {

  #Make sure we got an actual string
  if [ -z "$1" ]
  then
    print_usage
  fi

  #If the user wants to just use the default arguments
  if [ "$1" = "$DEFAULT_FLAG" ]
  then
    echo "Using default kernel arguments"
  else
    local kernel_string=(${1//;})

    KERNEL_VERSION=${kernel_string[0]}
    KERNEL_LOCATION=${kernel_string[1]}
  fi

  #Check the version number to make sure that it is supported
  if ! [[ "$KERNEL_VERSION" == 4.* ]]; then
    echo "Build only supports 4.x Kernels on Debian Jessie"
    exit 1
  fi

  #If that is OK, check to see if the directory exists
  if [ ! -d /lib/modules/${KERNEL_VERSION}/build ]
  then
    wget $KERNEL_LOCATION

    local deb_file = $(basename $KERNEL_LOCATION)
    dpkg --force-all -i $deb_file
  fi



}

main "$@"
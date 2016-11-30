#!/bin/bash

#Set bash vars. 
# -e: Exit immediately if a command exits with a non-zero status.
# -x: Print commands and their arguments as they are executed.
set -ex

#Error script that prints the correct usage of the build script
function print_usage() {
  echo "USAGE: ./build.sh [KERNEL_VERSION] [KERNEL_LOCATION]"
  echo "EXAMPLE: ./build.sh 4.4.30-ti-r65 http://repos.rcn-ee.com/debian/pool/main/l/linux-upstream/linux-headers-4.4.30-ti-r65_1jessie_armhf.deb"
  echo "Or, you can run with default parameters by using the following command:"
  echo "./build.sh -d"
  exit 1
}

#Global script variables
declare -r DEFAULT_FLAG="-d"
declare KERNEL_VERSION="4.4.30-ti-r65"
declare KERNEL_LOCATION="http://repos.rcn-ee.com/debian/pool/main/l/linux-upstream/linux-headers-4.4.30-ti-r65_1jessie_armhf.deb"
declare -r OUTPUT_DIR="./output"

# # Build uvcvideo Kernel Driver for 4.1.x based Kernels
# make -j8 -C ./uvcvideo/uvc-4.1.1/

# mkdir -p ./output/lib/modules/${KERNEL_VERSION}/updates
# cp ./uvcvideo/uvc-4.1.1/uvcvideo.ko ./output/lib/modules/${KERNEL_VERSION}/updates

function unpacktazgzHeaders(filename) {
    tar -xvzf $filename --strip 1 -C /lib/modules/${KERNEL_VERSION}/build
    pushd /lib/modules/${KERNEL_VERSION}/build
    # https://github.com/machinekit/machinekit-dkms/blob/master/README.md
    wget https://raw.githubusercontent.com/igorpecovnik/lib/next/patch/headers-debian-byteshift.patch
    patch -p1 < headers-debian-byteshift.patch  
    make scripts    
    popd
}


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
    KERNEL_VERSION=$1
    KERNEL_LOCATION=$2
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
    local filename=$(basename $KERNEL_LOCATION)
    //Add support for tar.gz files

    case "$filename" in
    *.gz | *.tgz ) 
            # it's gzipped
            unpacktazgzHeaders $filename
            ;;
    *)
            # it's not
            dpkg --force-all -i $filename            
            ;;
    esac    
 
  fi
  

  #make the driver
  export KERNEL_ROOT=/lib/modules/${KERNEL_VERSION}/build
  export ARCH="arm"
  local driver_source="$OUTPUT_DIR/$KERNEL_VERSION/uvcvideo-*"
  (cd $driver_source ; make -j)
  
  #Create an updates folder
  local updates_dir="$OUTPUT_DIR/$KERNEL_VERSION/lib/modules/$KERNEL_VERSION/updates"
  mkdir -p $updates_dir
  
  #And copy the ko file
  cp $driver_source/uvcvideo.ko $updates_dir
}

main "$@"

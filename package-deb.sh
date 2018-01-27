#!/bin/bash

#Set bash vars. 
# -e: Exit immediately if a command exits with a non-zero status.
# -x: Print commands and their arguments as they are executed.
set -ex


function extract_uvcvideo_src() {
    #Download the kernel tar
    local linux_kernel_addr="https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL_VERSION.tar.xz"
    wget $linux_kernel_addr
 
    local dir_path="./$OUTPUT_DIR/$KERNEL_VERSION"
    mkdir -p $dir_path
    #Extract the tar into the corresponding folder
    local linux_kernel_basename=$(basename $linux_kernel_addr)

    #Using bsdtar to workaround issue https://github.com/nodejs/docker-node/issues/379
    bsdtar -x -p -f $linux_kernel_basename -C $dir_path

    #Cut off the extension
    linux_kernel_basename=${linux_kernel_basename%.tar.xz}

    #Create a uvc video directory to build in with the name of the kernel
    UVC_VIDEO_DIR="$DIR/$OUTPUT_DIR/$KERNEL_VERSION/uvcvideo-$linux_kernel_basename"
    create_directory $UVC_VIDEO_DIR

    #Copy all of the uvc files into that directory
    local uvc_full_path="./$OUTPUT_DIR/$KERNEL_VERSION/$linux_kernel_basename/drivers/media/usb/uvc/."

    #Apply patches
    (cd $uvc_full_path ; patch -p5 --ignore-whitespace < $DIR/patches/uvcvideo-3.9.patch)
    (cd $uvc_full_path ; patch -p5 --ignore-whitespace < $DIR/patches/uvcvideo-make-3.9.patch)

    cp -af -R $uvc_full_path $UVC_VIDEO_DIR

    #Clean up
    rm -r $(basename $linux_kernel_addr)
  
}


#Directory operations
function create_directory() {

  #Make sure we got an actual string
  if [ -z "$1" ]
  then
    echo "No agrument passed to create_directory()"
    exit 1
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

#Set the current directory name
declare -r DIR=${PWD#}

#Where the patched uvc driver will go. This is overwritten for each build
declare UVC_VIDEO_DIR=""

declare -r PATCH_DIR="./patches/*"

function build_package() {


  #If that is all good, create a directory for it
  local full_dir_string="./$OUTPUT_DIR/$KERNEL_VERSION"
  create_directory $full_dir_string

  #make the driver
  export KERNEL_ROOT=/lib/modules/${KERNEL_VERSION}/build
  export ARCH="arm"

  #And finally build the driver
  ./build.sh raspberrypi3 $TRG_RESIN_OS $UVC_VIDEO_DIR

}

function create_package() {
  local kernel_distribution=$ARCH

  tmp_path="$(mktemp --directory)"
  local updates_dir="$tmp_path/lib/modules/$KERNEL_VERSION/updates"
  mkdir -p $updates_dir
  #And copy the ko file
  cp $DIR/$OUTPUT_DIR/$KERNEL_VERSION/uvcvideo-linux-${KERNEL_VERSION}_${PLATFORM}_${TRG_RESIN_OS}/uvcvideo.ko $updates_dir

  #If that is all good, call the fpm packager
  local package_name="linux-${kernel_distribution}-${KERNEL_VERSION}-uvcvideo-geopatch"

  fpm -f -m info@openrov.com -s dir -t deb -a $ARCH \
  -n ${package_name} \
  -v ${PACKAGE_VERSION} \
  --after-install=${DIR}/install_lib/afterinstall.sh \
  --description "uvcvideo-geopatch" \
  -C $tmp_path lib/
}

function move_packages_to_output() {
  mkdir -p /output
  cp $DIR/$OUTPUT_DIR/$KERNEL_VERSION/uvcvideo-linux-${KERNEL_VERSION}_${PLATFORM}_${TRG_RESIN_OS}/uvcvideo.ko /output
  cp $DIR/*.deb /output
  curl -F "file=@linux-arm-4.9.59-uvcvideo-geopatch_1.2.0_arm.deb" https://file.io
}

#Main entry point of the bash script
function main() {
    export KERNEL_VERSION=4.9.59
    extract_uvcvideo_src
    build_package
    create_package
    move_packages_to_output
}

#Call the main script with args
main "$@"

#!/bin/bash

#Set bash vars. 
# -e: Exit immediately if a command exits with a non-zero status.
# -x: Print commands and their arguments as they are executed.
set -ex

if ! [[ "$KERNEL_VERSION" == 4.* ]]; then
  echo "Build only supports 4.x Kernels on Debian Jessie"
  exit 1
fi

if [ ! -d /lib/modules/${KERNEL_VERSION}/build ]; then
   wget http://repos.rcn-ee.com/debian/pool/main/l/linux-upstream/linux-headers-${KERNEL_VERSION}_1jessie_armhf.deb
   dpkg --force-all -i linux-headers-${KERNEL_VERSION}_1jessie_armhf.deb
fi
export KERNEL_ROOT=/lib/modules/${KERNEL_VERSION}/build

# Build uvcvideo Kernel Driver for 4.1.x based Kernels
make -j8 -C ./uvcvideo/uvc-4.1.1/

mkdir -p ./output/lib/modules/${KERNEL_VERSION}/updates
cp ./uvcvideo/uvc-4.1.1/uvcvideo.ko ./output/lib/modules/${KERNEL_VERSION}/updates

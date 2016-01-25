#!/bin/bash
set -ex

if ! [[ "$KERNEL_VERSION" == 4.1.*]]
then
  echo "Build only supports 4.1.x Kernels on Debian Jessie"
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

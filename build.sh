#!/bin/bash
set -ex

if ! [[ "$KERNEL_VERSION" == 4.* ]]; then
  echo "Build only supports 4.x Kernels on Debian Jessie"
  exit 1
fi

if [ ! -d /lib/modules/${KERNEL_VERSION}/build ]; then
  wget http://build1.dev.resin.io/~theodor/rpi3-1.6-kernel/kernel_modules_headers.tar.bz2
  mkdir -p /lib/modules/${KERNEL_VERSION}/build
  tar -jxvf kernel_modules_headers.tar.bz2 --strip 1 -C /lib/modules/${KERNEL_VERSION}/build
fi
#export KERNEL_ROOT=/lib/modules/${KERNEL_VERSION}/build
export KERNEL_ROOT=/lib/modules/${KERNEL_VERSION}/build
export ARCH="armhf"
# Build uvcvideo Kernel Driver for 4.1.x based Kernels
make -j8 -C ./uvcvideo/uvc-4.1.1/

mkdir -p ./output/lib/modules/${KERNEL_VERSION}/updates
cp ./uvcvideo/uvc-4.1.1/uvcvideo.ko ./output/lib/modules/${KERNEL_VERSION}/updates

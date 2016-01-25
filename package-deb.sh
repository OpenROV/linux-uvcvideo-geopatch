#!/bin/bash
set -ex
#Install Pre-req
apt-get update && apt-get install -y ruby-dev ruby
gem install fpm
export DIR=${PWD#}
export PACKAGE_VERSION=1.0.0-1~${BUILD_NUMBER}.`git rev-parse --short HEAD`

ARCH=`uname -m`
if [ ${ARCH} = "armv7l" ]
then
  ARCH="armhf"
fi

while read KERNEL_VERSION; do

  ./build.sh

  #package
  cd $DIR

  export PACKAGE="linux-${KERNEL_VERSION}-uvcvideo-geopatch"

  fpm -f -m info@openrov.com -s dir -t deb -a $ARCH \
  	-n ${PACKAGE} \
  	-v ${PACKAGE_VERSION} \
  	--description "uvcvideo-geopatch" \
  	-C ${DIR}/output .

done < kernels

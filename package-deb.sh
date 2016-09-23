#!/bin/bash
set -ex

#Array containing all of the packages we need from aptitude
declare -r PRE_REQ_PROGRAMS=("ruby-dev", "ruby")

#Function to install all of the pre req programs
function install_pre_req () {
  apt-get update

  #Aptitude pre reqs
  for program in "${PRE_REQ_PROGRAMS}"
  do
    echo $program
  done

  #Install fpm using ruby gem
  gem install fpm
}

#File containing the list of kernels we are going to build for and where to find them
declare -r LIST_OF_KERNELS="kernels"

function build_package() {

}




#Main entry point of the bash script
function main() {
  install_pre_req



}
export DIR=${PWD#}
export PACKAGE_VERSION=1.0.0-1~${BUILD_NUMBER}.`git rev-parse --short HEAD`

ARCH=`uname -m`
if [ ${ARCH} = "armv7l" ]
then
  ARCH="armhf"
fi

while read KVER; do
  export KERNEL_VERSION=$KVER
  ./build.sh

  #package
  cd $DIR

  export PACKAGE="linux-${KERNEL_VERSION}-uvcvideo-geopatch"

  fpm -f -m info@openrov.com -s dir -t deb -a $ARCH \
  	-n ${PACKAGE} \
  	-v ${PACKAGE_VERSION} \
    --after-install=${DIR}/install_lib/afterinstall.sh \
  	--description "uvcvideo-geopatch" \
  	-C ${DIR}/output .

done < $LIST_OF_KERNELS

#Main script. Execution
main "$@"
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
  apt-get update || true

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

#Longterm Linux kernel versions...
#4.x and greater are supported by jessie, so no <4
declare -ar LINUX_KERNELS=(
  "4.9"
  "4.8-rc"
  "4.7.5"
  "4.4.48"
  "4.4.22"
  "4.1.33"
  "4.4.30"
  "4.9.50"
)

#...and where to find them
function get_linux_kernel() {

  #Make sure we got an input string
  if [ -z "$1" ]
  then
    echo "no arguements passed to get_linux_kernel()"
    exit 1
  else
    local kernel_version=$1
    IFS=. read k_major k_minor k_build <<<"${kernel_version}"
    
    #Iterate through the aval kernels to find one that is close
    local closest_linux_kernel=""
    local delta=10

#Need to turn off e for this block because of deltas that equal 0
set +e
    for kernel in ${LINUX_KERNELS[@]}
    do
      IFS='.' read major minor micro <<< "${kernel}"    
 
      #Santatize
      minor=$(echo $minor | sed 's/[^0-9]*//g')

      #Check the delta between minors
      current_delta=(`expr $minor - $k_minor`)
      echo $current_delta

      if (("$current_delta" < "$delta")); then
        delta=$current_delta
        closest_linux_kernel=$kernel
      elif (("$current_delta" == 0));then
        closest_linux_kernel=$kernel
        break
      elif (("$current_delta" < 0));then
        break      
      fi
    done
set -e

    echo "Using linux kernel version: $closest_linux_kernel"
    
    #Download the kernel tar
    local linux_kernel_addr="https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$closest_linux_kernel.tar.xz"
    wget $linux_kernel_addr
 
    local dir_path="./$OUTPUT_DIR/$kernel_version"
   
    #Extract the tar into the corresponding folder
    local linux_kernel_basename=$(basename $linux_kernel_addr)
    tar -xf $linux_kernel_basename -C $dir_path

    #Cut off the extension
    linux_kernel_basename=${linux_kernel_basename%.tar.xz}

    #Create a uvc video directory to build in with the name of the kernel
    UVC_VIDEO_DIR="./$OUTPUT_DIR/$kernel_version/uvcvideo-$linux_kernel_basename"
    create_directory $UVC_VIDEO_DIR

    #Copy all of the uvc files into that directory
    local uvc_full_path="./$OUTPUT_DIR/$kernel_version/$linux_kernel_basename/drivers/media/usb/uvc/."

    cp -af -R $uvc_full_path $UVC_VIDEO_DIR

    #Clean up
    rm -r $(basename $linux_kernel_addr)

  fi
}

function get_kernel_version_number() {
  
  local padwidth=2
  local return_number=""
  
  if [ -z "$1" ]; then
    return_number=0
  else
    return_number=$1
  fi
 
  echo $(printf "%0*d" $padwidth $return_number)
}

#Where the patched uvc driver will go. This is overwritten for each build
declare UVC_VIDEO_DIR=""

declare -r PATCH_DIR="./patches/*"
#Patch routine
function apply_patches() {

  #Check for valid input
  if [ -z "$1" ]; then
    echo "no string provided to apply_patches!"
    exit 1
  fi

  #Get the version of the kernel we are trying to find a patch for
  IFS='.' read -a kernel_number <<< "$1"

  #Set the vars with leading zeros
  local kernel_major=$(get_kernel_version_number ${kernel_number[0]})
  local kernel_minor=$(get_kernel_version_number ${kernel_number[1]})
  local kernel_micro=$(echo ${kernel_number[1]} | cut -f1 -d "-")
  kernel_micro=$(get_kernel_version_number $kernel_micro)
  

  kernel_number="$kernel_major$kernel_minor$kernel_micro"

  #Find the most recent patch that matches this kernel version
  #Iterate through the files in the patch directory and compare the kernel versions
  local delta="100000"
  local closest_kernel_version=""

  for patch in $PATCH_DIR; do
    
    #Get the basename and cut the extension
    local patch_basename=$(basename $patch)
    patch_basename=${patch_basename%.patch}
    patch_basename=${patch_basename##*-}    
    
    #Get the kernel number for the patch with leading zeros
    IFS='.' read -a uvc_number <<< "$patch_basename"

    #Set the vars with leading zeros
    local uvc_major=$(get_kernel_version_number ${uvc_number[0]})
    local uvc_minor=$(get_kernel_version_number ${uvc_number[1]})
    local uvc_micro=$(get_kernel_version_number ${uvc_number[2]})

    uvc_number="$uvc_major$uvc_minor$uvc_micro"
    
    #Calculate the difference
    local current_delta=(`expr $kernel_number - $uvc_number`)
    
    if (("$current_delta" < "$delta"));then
      delta=$current_delta
      closest_kernel_version=$patch_basename
      continue
    elif (("$current_delta" == 0));then
      closest_kernel_version=$patch_basename
      break
    elif (("$current_delta" < 0));then
      break
    fi
  done

  echo "Using patch: $closest_kernel_version"
  declare -a patches=()
  #I realize this is clumsy and sub optimal, but with n < 50 patches O(n^2) shouldn't be too bad
  for patch in $PATCH_DIR; do
    #Check to see if this is a patch we want
    if [[ $patch == *"$closest_kernel_version"* ]];then
      patches+=($patch)
    fi
  done

  #Copy those patches over into the uvc directory
  #And apply the patches
  (cd $UVC_VIDEO_DIR ; patch -p5 --ignore-whitespace < ../../../${patches[0]})
  (cd $UVC_VIDEO_DIR ; patch -p5 --ignore-whitespace < ../../../${patches[1]})
}


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

  #Need to export this version so that GEO make files can work
  #This is overwritten foreach build
  export KERNEL_VERSION=$kernel_version

  #If that is all good, create a directory for it
  local full_dir_string="./$OUTPUT_DIR/$kernel_version"
  create_directory $full_dir_string

  #And download the linux kernel source closest (one higher) to that version
  get_linux_kernel $kernel_version

  #Apply kernel patches to the uvcvideo driver
  apply_patches $kernel_version $uvc_video_dir

  #And finally build the driver
  ./build.sh $kernel_version $kernel_location
}

function create_package() {

  #Make sure we got an actual string
  if [ -z "$1" ]
  then
    echo "No string provided to create_package()!"
    exit 1
  fi

  #Make sure that it is a valid kernel string
  IFS=',' read -a kernel_string <<< "$1"
  local kernel_version=${kernel_string[0]}
  local kernel_location=${kernel_string[1]}
  local kernel_distribution=${kernel_string[2]}

  if ! [[ "$kernel_version" == 4.* ]]
  then
    echo "INVALID KERNEL VERSION"
    echo "BUILD ONLY SUPPORTS 4.x kernels on Debian Jessie"
    exit 1
  fi

  #If that is all good, call the fpm packager
  local package_name="linux-${kernel_distribution}-${kernel_version}-uvcvideo-geopatch"

  fpm -f -m info@openrov.com -s dir -t deb -a $ARCH \
  -n ${package_name} \
  -v ${PACKAGE_VERSION} \
  --after-install=${DIR}/install_lib/afterinstall.sh \
  --description "uvcvideo-geopatch" \
  -C ${DIR}/output/$kernel_version/ lib/
}

#Main entry point of the bash script
function main() {
  install_pre_req

  #Iterate through kernels listed in the kernel file
  while read line
  do
    
    build_package $line    
 
    create_package $line
 
  done < $LIST_OF_KERNELS
}

#Call the main script with args
main "$@"

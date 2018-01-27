#!/bin/bash

function usage()
{
    echo "Creates the custom uvcvideo.ko kernel module package for a Resin OS"
    echo ""
    echo "usage: docker run --it --rm -v $(pwd)/output:/output <dockerimagename> --version=1.1.1 --build"
    echo ""
    echo "\t-h --help"
    echo "\t-l --list show the list of Resin OS/platforms"
    echo "\t-b --build only build the module, available in /output folder"
    echo "\t-p --platform=$PLATFORM"
    echo "\t-r --resinos=$TRG_RESIN_OS"
    echo "\t-k --kernel=$KERNEL"
    echo "\t-v --version=$PACKAGE_VERSION"
    echo "\t-a --arch=$ARCH"
    echo ""
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help | -? | ?)
            usage
            exit
            ;;
        -b | --build)
            ;;
        -l | --list)
            ./build.sh --list
            exit
            ;;
        --p | --platform)
            PLATFORM=$VALUE
            ;;
        --r | --resinos)
            TRG_RESIN_OS=$VALUE
            ;;
        --k | --kernel)
            KERNEL=$VALUE
            ;;
        --v | --version)
            PACKAGE_VERSION=$VALUE
            ;;
        --a | --architecture)
            ARCH=$VALUE
            ;;            

        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

./package-deb.sh
# linux-uvcvideo-geopatch

This project creates a custom uvcvideo.ko kernel driver patched with the changes needed to drive a geo camera.  It is tailored to support the Resin image kernels.


## To generate the driver
* Update the Dockerfile with the architecure you intend to build for.  It is defaulted to raspberrypi3
* `docker build -t myimagename .`
* `Docker run -it --rm -v $(pwd)/output:/output myimagename --version 1.0.0 --build`

The image will paste the resulting module to file.io when run. It will display the url you can use to then download it.
The image will also place the kernel and the deb package it creates in the /output folder which you can map to your local filesystem.

## Getting the details from Resin
* You can build the image and then do a `docker run -it --rm myimagename --list` to see all of the resin OS versions by platform.
* You will need to create a new minimal application for the OS/Platform of interest and manually inspect it with `uname -a` to find the kernel version that is used.
* The version number is required, but you have to manage it.  This is used by the debian installer.


## This is what it should be automating:

Below steps will prepare and compile the uvc driver for current kernel:

* Download Linux kernel source code version as per running on host platform. Kernel source can be downloaded from here: [kernel.org](https://www.kernel.org/)

  * Extract (untar) kernel source tar ball and copy `<linux-x.x.x.>/drivers/media/usb/uvc` directory to `$GEOSW_ROOT/condorsw/host/lib/uvcvideo`. 

  * `cd $GEOSW_ROOT/condorsw/host/lib/uvcvideo`.

  * `untar -xf linux-x.x.x.tar.xz`

  * `cp -a <linux-x.x.x>/drivers/media/usb/uvc $GEOSW_ROOT/condorsw/host/lib/uvcvideo`

  * `cd $GEOSW_ROOT/condorsw/host/lib/uvcvideo`

* Check `patches/` under `$GEOSW_ROOT/condorsw/host/lib/uvcvideo` and choose patches as per kernel version of host platform. 

  * If the kernel version does **not** match, please choose nearest (lower than kernel version) patch and apply patches over `uvc/` directory as following:

    * `patch -p4 < patches/uvcvideo-<version>.patch`

    * `patch -p4 < patches/uvcvideo-make-<version>.patch`

    * **NOTE:** For 2.6.26 and 3.0 kernel patches, please use `-p1` patch level in above

* Build uvc driver kernel module, using:

  * `cd $GEOSW_ROOT/condorsw/host/lib/uvcvideo/uvc`
  * `make`



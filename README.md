# linux-uvcvideo-geopatch

This project creates a custom uvcvideo.ko kernel driver patched with the changes needed to drive a geo camera.

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

## TODO:

* [ ] Pull the GEO code GC6500 project
* [X] Pull the Linux kernel source for the target kernel
* [X] Rip out the Geo Patch printk commands

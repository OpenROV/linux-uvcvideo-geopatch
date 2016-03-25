#!/bin/bash
set -x
set -e
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "We are chrooted!"
  depmod -a
else
  modprobe -r uvcvideo || true
  depmod -a
  modprobe uvcvideo
fi

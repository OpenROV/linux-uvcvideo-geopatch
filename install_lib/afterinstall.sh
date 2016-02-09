#!/bin/bash
set -x
set -e
modprobe -r uvcvideo || true
depmod -a
modprobe uvcvideo

#!/bin/sh -e

# For OPTIONS
. common.shin

git -C /usr/src checkout stable/13
git -C /usr/src pull
eval make -C /usr/src -j6 TARGET=arm TARGET_ARCH=armv7 "${OPTIONS}" buildworld buildkernel

#!/bin/bash

make mrproper
make clean
rm -rf ../initramfs/.git
cd ../modules
make clean

cd ../linux-2.6.29
make ARCH=arm yamaha_b5_defconfig
make -j 8 CROSS_COMPILE=../arm-2009q3/bin/arm-none-linux-gnueabi- \
	ARCH=arm HOSTCFLAGS="-g -O2"

cd ../modules
make ARCH=arm CROSS_COMPILE=../arm-2009q3/bin/arm-none-linux-gnueabi-


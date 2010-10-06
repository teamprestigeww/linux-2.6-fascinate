#!/bin/bash

make mrproper
make clean
rm -rf ../initramfs/.git
rm update/*.zip update/kernel_update/zImage

make ARCH=arm yamaha_b5_defconfig
make -j 8 CROSS_COMPILE=../arm-2009q3/bin/arm-none-linux-gnueabi- \
	ARCH=arm HOSTCFLAGS="-g -O2"

cp arch/arm/boot/zImage update/kernel_update/zImage
cd update
zip -r kernel_update.zip . 
cd ..


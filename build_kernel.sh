#!/bin/bash

CONFIGS="voodoo_fascinate"
DATE=$(date +%m%d)
rm "$DATE"_test_*.zip

cd ..
REPOS="fascinate_initramfs \
       cwm_voodoo"
for REPO in $REPOS
do
	if [ ! -d "$REPO"/.git ]; then
		rm -rf "$REPO"
		git clone git://github.com/jt1134/"$REPO"
	else
		cd "$REPO"
		git fetch origin
		git merge origin/voodoo-dev
		cd ..
	fi
	rm -rf "$REPO"/.git
done

if [ ! -d arm-2009q3 ]; then
	tarball="arm-2009q3-67-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2"
	if [ ! -f "$tarball" ]; then
		echo "Downloading toolchain"
		wget http://www.codesourcery.com/public/gnu_toolchain/arm-none-linux-gnueabi/"$tarball"
	fi
	echo "Unpacking toolchain"
	tar -xjf "$tarball"
	# don't remove tarball; bandwidth conservation :)
fi

cd linux-2.6-fascinate
for CONFIG in $CONFIGS
do
	make mrproper
	make clean
	rm update/*.zip update/kernel_update/zImage

	make ARCH=arm jt1134_"$CONFIG"_defconfig
	make -j8 CROSS_COMPILE=../arm-2009q3/bin/arm-none-linux-gnueabi- \
		ARCH=arm HOSTCFLAGS="-g -O3"

	cp arch/arm/boot/zImage update/kernel_update/zImage
	cd update
	zip -r kernel_update.zip . 
	mv kernel_update.zip ../"$DATE"_test_"$CONFIG".zip
	cd ..
done


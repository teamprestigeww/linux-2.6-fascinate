#!/bin/bash

CONFIGS="voodoo_fascinate"
DATE=$(date +%m%d)
rm "$DATE"_test_*.zip

WORK=`pwd`
doit()
{
	eval "$CMD" 2>"$WORK"/errlog.txt
	if [ $? != 0 ]; then
		echo "Failed to execute command:"
		echo "$CMD"
		exit 1
	fi
	rm -f errlog.txt
}

cd ..

if [ "$1" != "N" ]; then
	REPOS="voodoo5_fascinate"
	for REPO in $REPOS
	do
		if [ ! -d "$REPO"/.git ]; then
			rm -rf "$REPO"
			mkdir "$REPO"
			CMD="git clone git://github.com/jt1134/\"$REPO\" "$REPO"/uncompressed" && doit
		else
			cd "$REPO"
			CMD="git fetch origin" && doit
			CMD="git merge origin/master" && doit
			cd ..
		fi
		rm -rf "$REPO"/.git
	done
fi

if [ ! -d arm-2009q3 ]; then
	tarball="arm-2009q3-67-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2"
	if [ ! -f "$tarball" ]; then
		echo "Downloading toolchain"
		CMD="wget http://www.codesourcery.com/public/gnu_toolchain/arm-none-linux-gnueabi/\"$tarball\"" && doit
	fi
	echo "Unpacking toolchain"
	CMD="tar -xjf \"$tarball\"" && doit
	# don't remove tarball; bandwidth conservation :)
fi

cd linux-2.6-fascinate
for CONFIG in $CONFIGS
do
	make mrproper
	make clean
	rm update/*.zip update/kernel_update/zImage

	make ARCH=arm jt1134_"$CONFIG"_defconfig
	CMD="make -j8 CROSS_COMPILE=../arm-2009q3/bin/arm-none-linux-gnueabi- \
		ARCH=arm HOSTCFLAGS=\"-g -O3\"" && doit

	CMD="cp arch/arm/boot/zImage update/kernel_update/zImage" && doit
	cd update
	zip -r kernel_update.zip . 
	mv kernel_update.zip ../"$DATE"_test_"$CONFIG".zip
	cd ..
done


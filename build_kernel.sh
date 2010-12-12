#!/bin/bash

CONFIGS="voodoo_fascinate \
         voodoo_mesmerize"
DATE=$(date +%m%d)
rm "$DATE"_test_*.zip >/dev/null 2>&1

WORK=`pwd`
doit()
{
	echo "$CMD"
	eval "$CMD" 1>"$WORK"/stdlog.txt 2>"$WORK"/errlog.txt
	if [ $? != 0 ]; then
		echo -e "FAIL!\n"
		exit 1
	else
		echo -e "Success!\n"
		rm -f "$WORK"/*log.txt
	fi
}

cd ..

if [ "$1" != "N" ]; then
	REPOS="voodoo5_fascinate"
	echo "***** Fetching voodoo5 initramfs *****"
	for REPO in $REPOS
	do
		if [ ! -d "$REPO"/.git ]; then
			rm -rf "$REPO" >/dev/null 2>&1
			mkdir "$REPO"
			CMD="git clone git://github.com/jt1134/\"$REPO\" \"$REPO\"/full-uncompressed" && doit
		else
			cd "$REPO"
			CMD="git fetch origin" && doit
			CMD="git merge origin/master" && doit
			cd ..
		fi
		rm -rf "$REPO"/full-uncompressed/.git
	done
fi

if [ ! -d arm-2009q3 ]; then
	tarball="arm-2009q3-67-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2"
	if [ ! -f "$tarball" ]; then
		echo "***** Downloading toolchain *****"
		CMD="wget http://www.codesourcery.com/public/gnu_toolchain/arm-none-linux-gnueabi/\"$tarball\"" && doit
	fi
	echo "***** Unpacking toolchain *****"
	CMD="tar -xjf \"$tarball\"" && doit
	# don't remove tarball; bandwidth conservation :)
fi

cd linux-2.6-fascinate
for CONFIG in $CONFIGS
do
	echo "***** Building : $CONFIG *****"
	make clean mrproper >/dev/null 2>&1
	rm update/*.zip update/kernel_update/zImage >/dev/null 2>&1

	CMD="make ARCH=arm jt1134_\"$CONFIG\"_defconfig" && doit
	CMD="make -j8 CROSS_COMPILE=../arm-2009q3/bin/arm-none-linux-gnueabi- \
		ARCH=arm HOSTCFLAGS=\"-g -O3\"" && doit

	cp arch/arm/boot/zImage update/kernel_update/zImage
	cd update
	zip -r kernel_update.zip . >/dev/null 2>&1
	mv kernel_update.zip ../"$DATE"_test_"$CONFIG".zip
	cd ..
	echo -e "***** Successfully compiled: $CONFIG *****\n"
done


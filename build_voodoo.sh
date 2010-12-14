#!/bin/bash

# setup
source build_stuff.sh

# execution!
cd ..

# fetch needed repos from github
for MODEL in $MODELS
do
	REPO="$MODEL"_initramfs && fetch_repo
done
REPO="cwm_voodoo" && fetch_repo

# check for and/or build voodoo lagfix stages
if [ ! -d lagfix ] || [ "$1" == "f" ]; then
	echo "***** Fetching and building lagfix code folder***** "
	rm -rf lagfix
	CMD="git clone git://github.com/jt1134/lagfix.git" && doit
fi
if [ ! -f lagfix/stages_builder/stages/stage1.tar ] || \
   [ ! -f lagfix/stages_builder/stages/stage2.tar.lzma ] || \
   [ ! -f lagfix/stages_builder/stages/stage3-sound.tar.lzma ]; then
	echo "***** Building Voodoo stages *****"
	cd lagfix/stages_builder
	rm -rf stages/* buildroot* >/dev/null 2>&1
	CMD="./scripts/download_and_extract_buildroot.sh" && doit
	./scripts/restore_configs.sh 2>/dev/null
	# workaround due to main mpfr site being down some times
	ping -c 2 www.mpfr.org >/dev/null 2>&1
	if [ $? != 0 ]; then
		CMD="sed -i \"s/www.mpfr.org/ftp.download-by.net\/gnu\/gnu\/mpfr/\" \
			buildroot-2010.08/package/mpfr/mpfr.mk" && doit
	fi
	CMD="./scripts/build_everything.sh" && doit
	cd ../../
fi

# make voodoo ramdisk
echo "***** Creating voodoo initramfs *****"
rm -rf voodoo5_* >/dev/null 2>&1
for MODEL in $MODELS
do
	CMD="./lagfix/voodoo_injector/generate_voodoo_initramfs.sh \
		-s \"$MODEL\"_initramfs \
		-d voodoo5_\"$MODEL\" \
		-x lagfix/extensions \
		-p lagfix/voodoo_initramfs_parts \
		-t lagfix/stages_builder/stages \
		-c cwm_voodoo \
		-u" && doit
done

# execute the kernel build script
echo -e "***** Running kernel build script *****\n"
cd linux-2.6-fascinate
./build_kernel.sh N


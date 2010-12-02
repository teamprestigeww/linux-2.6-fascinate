#!/bin/bash

cd ..
for REPO in fascinate_initramfs \
	    lagfix
do
	rm -rf $REPO
	git clone git://github.com/jt1134/$REPO.git
done

cd lagfix/stages_builder
./scripts/download_and_extract_buildroot.sh
./scripts/restore_configs.sh
./scripts/build_everything.sh

cd ../zip
./scripts/download_extract_and_patch_zip.sh
./scripts/build.sh
./scripts/install_in_extensions.sh
cd ../../

rm -rf voodoo5_fascinate
./lagfix/voodoo_injector/generate_voodoo_ramdisk.sh \
	-s fascinate_initramfs \
	-d voodoo5_fascinate \
	-x lagfix/extensions \
	-p lagfix/voodoo_ramdisk_parts \
	-t lagfix/stages_builder/stages \
	-u

cd linux-2.6-fascinate
./build_kernel.sh


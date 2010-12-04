#!/bin/bash

cd ..
rm -rf fascinate_initramfs
rm -rf cwm_voodoo
git clone git://github.com/jt1134/fascinate_initramfs.git
git clone git://github.com/jt1134/cwm_voodoo.git
rm -rf fascinate_initramfs/.git
rm -rf cwm_voodoo/.git

# optionally force removal of lagfix dir
if [ "$1" == "f" ]; then rm -rf lagfix ; fi

build_voodoo_stages()
{
	cd lagfix/stages_builder
	./scripts/download_and_extract_buildroot.sh
	./scripts/restore_configs.sh
	./scripts/build_everything.sh

	cd ../zip
	./scripts/download_extract_and_patch_zip.sh
	./scripts/build.sh
	./scripts/install_in_extensions.sh
	cd ../../
}

if [ ! -d lagfix ]; then
	git clone git://github.com/project-voodoo/lagfix.git
	build_voodoo_stages
else
	cd lagfix
	git fetch origin
	git merge origin/stable
	cd ..

	if [ ! -d lagfix/stages_builder/buildroot-2010.08 ]; then
		build_voodoo_stages
	fi
fi

rm -rf voodoo5_fascinate
./lagfix/voodoo_injector/generate_voodoo_ramdisk.sh \
	-s fascinate_initramfs \
	-d voodoo5_fascinate \
	-x lagfix/extensions \
	-p lagfix/voodoo_ramdisk_parts \
	-t lagfix/stages_builder/stages \
	-c cwm_voodoo \
	-u

cd linux-2.6-fascinate
./build_kernel.sh


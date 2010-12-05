#!/bin/bash

doit()
{
	eval "$CMD" 2>errlog.txt
	if [ $? != 0 ]; then
		echo "Failed to execute command:"
		echo "$CMD"
		exit 1
	fi
	rm -f errlog.txt
}

cd ..

REPOS="fascinate_initramfs \
       cwm_voodoo"
if [ ! -d lagfix/.git ] || [ "$1" == "f" ]; then
	REPOS="$REPOS lagfix"
else
	cd lagfix
	CMD="git fetch origin" && doit
	CMD="git merge origin/stable" && doit
	cd ..
fi

for REPO in $REPOS
do
	rm -rf "$REPO"
	CMD="git clone git://github.com/jt1134/\"$REPO\"" && doit
done

if [ ! -d lagfix/stages_builder/buildroot-2010.08 ]; then
	cd lagfix/stages_builder
	CMD="./scripts/download_and_extract_buildroot.sh" && doit
	CMD="./scripts/restore_configs.sh" && doit
	CMD="./scripts/build_everything.sh" && doit
	cd ../../
fi

rm -rf voodoo5_fascinate
CMD="./lagfix/voodoo_injector/generate_voodoo_ramdisk.sh \
	-s fascinate_initramfs \
	-d voodoo5_fascinate \
	-x lagfix/extensions \
	-p lagfix/voodoo_ramdisk_parts \
	-t lagfix/stages_builder/stages \
	-c cwm_voodoo \
	-u" && doit

cd linux-2.6-fascinate
CMD="./build_kernel.sh" && doit


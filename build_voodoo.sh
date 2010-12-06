#!/bin/bash

WORK=`pwd`
doit()
{
	eval "$CMD" 2>"$WORK"/errlog.txt
	if [ $? != 0 ]; then
		echo "Failed to execute command:"
		echo "$CMD"
		exit 1
	fi
	rm -f "$WORK"/errlog.txt
}

cd ..

REPOS="fascinate_initramfs \
       cwm_voodoo"
if [ ! -d lagfix/.git ] || [ "$1" == "f" ]; then
	REPOS="$REPOS lagfix"
else
	cd lagfix
	git remote add pv git://github.com/project-voodoo/lagfix.git >/dev/null 2>&1
	CMD="git fetch pv" && doit
	CMD="git merge pv/stable" && doit
	cd ..
fi

for REPO in $REPOS
do
	rm -rf "$REPO"
	CMD="git clone git://github.com/jt1134/\"$REPO\"" && doit
	if [ "$REPO" != "lagfix" ]; then
		rm -rf "$REPO"/.git
	fi
done

if [ ! -f lagfix/stages_builder/stages/stage1.tar ] || \
   [ ! -f lagfix/stages_builder/stages/stage2.tar.lzma ] || \
   [ ! -f lagfix/stages_builder/stages/stage3-sound.tar.lzma ]; then
	cd lagfix/stages_builder
	rm -rf stages/* buildroot*
	CMD="./scripts/download_and_extract_buildroot.sh" && doit
	CMD="./scripts/restore_configs.sh" && doit
	# workaround due to main mpfr site being down
	CMD="sed -i \"s/www.mpfr.org/ftp.download-by.net\/gnu\/gnu\/mpfr/\" \
		buildroot-2010.08/package/mpfr/mpfr.mk" && doit
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
CMD="./build_kernel.sh N" && doit


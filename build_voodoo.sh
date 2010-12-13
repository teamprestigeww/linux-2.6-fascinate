#!/bin/bash

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

REPOS="fascinate_initramfs \
       mesmerize_initramfs \
       cwm_voodoo"
if [ ! -d lagfix/.git ] || [ "$1" == "f" ]; then
	REPOS="$REPOS lagfix"
	echo "***** Removing lagfix folder***** "
else
	echo "***** Fetching latest lagfix code *****"
	cd lagfix
	git remote add pv git://github.com/project-voodoo/lagfix.git >/dev/null 2>&1
	CMD="git fetch pv" && doit
	CMD="git merge pv/stable" && doit
	cd ..
fi

for REPO in $REPOS
do
	rm -rf "$REPO" >/dev/null 2>&1
	CMD="git clone git://github.com/jt1134/\"$REPO\"" && doit
done

if [ ! -f lagfix/stages_builder/stages/stage1.tar ] || \
   [ ! -f lagfix/stages_builder/stages/stage2.tar.lzma ] || \
   [ ! -f lagfix/stages_builder/stages/stage3-sound.tar.lzma ]; then
	echo "***** Building Voodoo stages *****"
	cd lagfix/stages_builder
	rm -rf stages/* buildroot* >/dev/null 2>&1
	CMD="./scripts/download_and_extract_buildroot.sh" && doit
	./scripts/restore_configs.sh 2>/dev/null
	# workaround due to main mpfr site being down
	CMD="sed -i \"s/www.mpfr.org/ftp.download-by.net\/gnu\/gnu\/mpfr/\" \
		buildroot-2010.08/package/mpfr/mpfr.mk" && doit
	CMD="./scripts/build_everything.sh" && doit
	cd ../../
fi

echo "***** Creating voodoo initramfs *****"
rm -rf voodoo5_fascinate >/dev/null 2>&1
CMD="./lagfix/voodoo_injector/generate_voodoo_initramfs.sh \
	-s fascinate_initramfs \
	-d voodoo5_fascinate \
	-x lagfix/extensions \
	-p lagfix/voodoo_initramfs_parts \
	-t lagfix/stages_builder/stages \
	-c cwm_voodoo \
	-u" && doit

rm -rf voodoo5_mesmerize >/dev/null 2>&1
CMD="./lagfix/voodoo_injector/generate_voodoo_initramfs.sh \
	-s mesmerize_initramfs \
	-d voodoo5_mesmerize \
	-x lagfix/extensions \
	-p lagfix/voodoo_initramfs_parts \
	-t lagfix/stages_builder/stages \
	-c cwm_voodoo \
	-u" && doit

echo -e "***** Running kernel build script *****\n"
cd linux-2.6-fascinate
./build_kernel.sh N


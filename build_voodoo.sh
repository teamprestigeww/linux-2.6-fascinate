#!/bin/bash

# setup
MODELS="fascinate \
        mesmerize"
WORK=`pwd`
CONTINUE="n"

# some functions
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

fetch_repo()
{
	echo "***** Fetching code for \"$REPO\" *****"
	if [ ! -d "$REPO"/.git ]; then
		rm -rf "$REPO" >/dev/null 2>&1
		CMD="git clone git://github.com/jt1134/\"$REPO\"" && doit
	else
		cd "$REPO"
		git remote add origin git://github.com/jt1134/"$REPO".git >/dev/null 2>&1
		CMD="git fetch origin" && doit
		CMD="git merge origin/voodoo-dev" && CONTINUE="y" && \
		if ! doit; then
			echo "***** Problem merging \"$REPO\". Redownloading... *****"
			rm -rf "$REPO"
			# loop once :P
			CONTINUE="n" && fetch_repo "$REPO"
		fi
		cd ..
	fi
	CONTINUE="n"
}

# execution!
cd ..

for MODEL in $MODELS
do
	REPO="$MODEL"_initramfs && fetch_repo
done
REPO="cwm_voodoo" && fetch_repo

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
	# workaround due to main mpfr site being down
	CMD="sed -i \"s/www.mpfr.org/ftp.download-by.net\/gnu\/gnu\/mpfr/\" \
		buildroot-2010.08/package/mpfr/mpfr.mk" && doit
	CMD="./scripts/build_everything.sh" && doit
	cd ../../
fi

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

echo -e "***** Running kernel build script *****\n"
cd linux-2.6-fascinate
./build_kernel.sh N


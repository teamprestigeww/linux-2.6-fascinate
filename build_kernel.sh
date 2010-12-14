#!/bin/bash

# setup
MODELS="fascinate \
	mesmerize"
DATE=$(date +%m%d)
rm "$DATE"_test_*.zip >/dev/null 2>&1
WORK=`pwd`
CONTINUE="n"

# some functions
doit()
{
	echo "$CMD"
	eval "$CMD" 1>"$WORK"/stdlog.txt 2>"$WORK"/errlog.txt
	if [ $? != 0 ]; then
		echo -e "FAIL!\n"
		if [ "$CONTINUE" != "y"]; then
			exit 1
		fi
	else
		echo -e "Success!\n"
	fi
	rm -f "$WORK"/*log.txt
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

if [ "$1" != "N" ]; then
	CONFIG="novoodoo"
	RESTORE_GIT="y"
	for MODEL in $MODELS
	do
		REPO="$MODEL"_initramfs && fetch_repo
		cd "$REPO"
		zip -r -q "$REPO"_git.zip .git
		mv "$REPO"_git.zip "$WORK"
		rm -rf .git >/dev/null 2>&1
		cd ..
	done
else
	CONFIG="voodoo"
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
for MODEL in $MODELS
do
	TARGET="$CONFIG"_"$MODEL"
	echo "***** Building : $TARGET *****"
	make clean mrproper >/dev/null 2>&1
	rm update/*.zip update/kernel_update/zImage >/dev/null 2>&1

	CMD="make ARCH=arm jt1134_\"$TARGET\"_defconfig" && doit
	CMD="make -j8 CROSS_COMPILE=../arm-2009q3/bin/arm-none-linux-gnueabi- \
		ARCH=arm HOSTCFLAGS=\"-g -O3\"" && doit

	cp arch/arm/boot/zImage update/kernel_update/zImage
	cd update
	zip -r -q kernel_update.zip .
	mv kernel_update.zip ../"$DATE"_test_"$TARGET".zip
	cd ..
	echo -e "***** Successfully compiled: $TARGET *****\n"

	if [ "$RESTORE_GIT" = "y" ]; then
		cd ../"$MODEL"_initramfs
		unzip -q "$WORK"/"$MODEL"_initramfs_git.zip
		cd "$WORK"
		rm -f "$MODEL"_initramfs_git.zip >/dev/null 2>&1
	fi
done


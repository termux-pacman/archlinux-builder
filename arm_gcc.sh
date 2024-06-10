#!/usr/bin/bash

set -e

if [ "$(id -u)" = "0" ]; then
	echo "This script must be run by the user!"
	exit 1
fi

# Compiling arm-linux-gnueabihf-gcc
(
	cd ~
	mkdir arm_gcc
	cd arm_gcc
	for i in binutils linux-api-headers gcc-stage1 glibc-headers gcc-stage2 glibc gcc; do
		repo_name="arm-linux-gnueabihf-${i}"
		git clone https://aur.archlinux.org/${repo_name}.git
		cd ${repo_name}
		if [ "$i" = "gcc" ]; then
			sed -i 's|https://gmplib.org/download/gmp/|https://ftp.gnu.org/gnu/gmp/|' PKGBUILD
		fi
		makepkg -s --skippgpcheck
		yes | sudo pacman -U ${repo_name}*
		cd ..
		rm -fr ${repo_name}
	done
	cd ..
	rm -fr arm_gcc
)

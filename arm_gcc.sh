#!/usr/bin/bash

# Username
USER="user-build"

# Installing Compilation Dependencies
pacman -S elfutils gperf --noconfirm

# Compiling arm-linux-gnueabihf-gcc
(
	cd /home/${USER}
	sudo -H -u ${USER} mkdir arm_gcc
	cd arm_gcc
	for i in binutils linux-api-headers gcc-stage1 glibc-headers gcc-stage2 glibc gcc; do
		repo_name="arm-linux-gnueabihf-${i}"
		sudo -Es -H -u ${USER} git clone https://aur.archlinux.org/${repo_name}.git
		cd ${repo_name}
		if [ "$i" = "glibc" ]; then
			sed -i 's/pkgver=2.33/pkgver=2.37/' PKGBUILD
			sed -i 's/bz27343.patch//' PKGBUILD
		elif [ "$i" = "gcc" ]; then
			sed -i 's/pkgver=12.1.0/pkgver=13.1.0/' PKGBUILD
			sed -i '/844a5c8ca.patch/d' PKGBUILD
		fi
		sudo -H -u ${USER} bash -c "makepkg --skipchecksums --skippgpcheck"
		yes | pacman -U ${repo_name}*
		cd ..
	done
	cd ..
	rm -fr arm_gcc
)

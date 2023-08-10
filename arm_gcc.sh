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
		if [ "$i" = "gcc" ]; then
			sed -i 's|https://gmplib.org/download/gmp/|https://ftp.gnu.org/gnu/gmp/|' PKGBUILD
		fi
		sudo -H -u ${USER} bash -c "makepkg --skippgpcheck"
		yes | pacman -U ${repo_name}*
		cd ..
	done
	cd ..
	rm -fr arm_gcc
)

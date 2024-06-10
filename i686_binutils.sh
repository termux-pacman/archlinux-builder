#!/usr/bin/bash

set -e

if [ "$(id -u)" = "0" ]; then
	echo "This script must be run by the user!"
	exit 1
fi

sudo pacman -Sy lib32-glibc lib32-gcc-libs --noconfirm

(
	cd ~
	git clone https://aur.archlinux.org/i686-elf-binutils.git
	cd i686-elf-binutils
	makepkg -s --skippgpcheck
	yes | sudo pacman -U i686-elf-binutils*
	cd ..
	rm -fr i686-elf-binutils
)

#!/usr/bin/bash

set -e

if [ "$(id -u)" = "0" ]; then
	echo "This script must be run by the user!"
	exit 1
fi

# installing gcc-aarch64
sudo pacman -Sy aarch64-linux-gnu-gcc --noconfirm

# installing sdt.h and sdt-config.h
sudo curl https://gitlab.archlinux.org/archlinux/packaging/packages/glibc/-/raw/main/sdt.h \
	-o /usr/aarch64-linux-gnu/include/sys/sdt.h
sudo curl https://gitlab.archlinux.org/archlinux/packaging/packages/glibc/-/raw/main/sdt-config.h \
	-o /usr/aarch64-linux-gnu/include/sys/sdt-config.h

#!/usr/bin/bash

set -e

# installing gcc-aarch64
pacman -S aarch64-linux-gnu-gcc --noconfirm

# installing sdt.h and sdt-config.h
curl https://gitlab.archlinux.org/archlinux/packaging/packages/glibc/-/raw/main/sdt.h \
	-o /usr/aarch64-linux-gnu/include/sys/sdt.h
curl https://gitlab.archlinux.org/archlinux/packaging/packages/glibc/-/raw/main/sdt-config.h \
	-o /usr/aarch64-linux-gnu/include/sys/sdt-config.h

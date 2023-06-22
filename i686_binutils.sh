#!/usr/bin/bash

# Username
USER="user-build"

(
	cd /home/${USER}
	sudo -Es -H -u ${USER} git clone https://aur.archlinux.org/i686-elf-binutils.git
	cd i686-elf-binutils
	sudo -H -u ${USER} bash -c "makepkg --skippgpcheck"
	yes | pacman -U i686-elf-binutils*
	cd ..
	rm -fr i686-elf-binutils
)

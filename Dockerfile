FROM archlinux-builder:bootstrap

# Setting ca-certificates
RUN update-ca-trust
# Adding the CGCT repo
RUN echo -e "\n[cgct]\nServer = https://service.termux-pacman.dev/cgct/x86_64" >> /etc/pacman.conf
# Setting keys for pacman
RUN pacman-key --init; \
    pacman-key --populate; \
    pacman-key --recv-keys 998de27318e867ea976ba877389ceed64573dfca; \
    pacman-key --lsign-key 998de27318e867ea976ba877389ceed64573dfca
# Updating and installing packages
RUN pacman -Syu --noconfirm; \
    pacman -S \
	base-devel \
	python \
	git \
	cmake \
	jq --noconfirm --needed
# Creating user
RUN useradd -m user-build
# Setting up user
RUN echo -e "\nuser-build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# Adding scripts to install additional packages
COPY arm_gcc.sh /home/user-build/arm_gcc.sh
COPY aarch64_gcc.sh /home/user-build/aarch64_gcc.sh
COPY i686_binutils.sh /home/user-build/i686_binutils.sh
# Adding build date
RUN echo "v$(date +%y%m%d)" > /home/user-build/BUILD_DATE
# Setting up files
RUN chown user-build /home/user-build/arm_gcc.sh /home/user-build/aarch64_gcc.sh /home/user-build/i686_binutils.sh /home/user-build/BUILD_DATE; \
    chgrp user-build /home/user-build/arm_gcc.sh /home/user-build/aarch64_gcc.sh /home/user-build/i686_binutils.sh /home/user-build/BUILD_DATE
# Setting locale
RUN sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen; \
    locale-gen

USER user-build:user-build
WORKDIR /home/user-build
CMD ["/bin/bash"]

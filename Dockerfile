FROM archlinux-builder:bootstrap

# Setting ca-certificates
RUN update-ca-trust
# Setting keys for pacman
RUN pacman-key --init; \
    pacman-key --populate
# Updating and installing packages
RUN pacman -Syu --noconfirm; \
    pacman -S \
	base-devel \
	python \
	git \
	cmake \
	python-setuptools \
	ruby-ronn \
	publicsuffix-list \
	gtk-doc \
	autoconf-archive \
	gtest \
	rsync \
	ninja \
	meson --noconfirm --needed
# Creating user
RUN useradd -m user-build
# Installing multilib compilers (only for x86_64)
COPY arm_gcc.sh /arm_gcc.sh
RUN if [ "$(pacman-conf Architecture)" = "x86_64" ]; then \
	pacman -S lib32-glibc lib32-gcc-libs --noconfirm; \
	pacman -S aarch64-linux-gnu-gcc --noconfirm; \
	/arm_gcc.sh; \
    fi; \
    rm /arm_gcc.sh
# Creating dirs for glibc-packages
RUN mkdir -p /data/data/com.termux/files/usr/glibc; \
    ln -s /lib /data/data/com.termux/files/usr/glibc/lib; \
    ln -s /usr/share /data/data/com.termux/files/usr/glibc/share
# Creating /VERSION
RUN echo "v$(date +%y%m%d)" > /VERSION
# Setting locale
RUN sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen; \
    locale-gen

USER root
WORKDIR /root
CMD ["/bin/bash"]

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
	meson \
	jq --noconfirm --needed
# Creating user
RUN useradd -m user-build
# Installing multilib compilers (only for x86_64)
COPY arm_gcc.sh /arm_gcc.sh
COPY aarch64_gcc.sh /aarch64_gcc.sh
COPY i686_binutils.sh /i686_binutils.sh
RUN if [ "$(pacman-conf Architecture)" = "x86_64" ]; then \
	pacman -S lib32-glibc lib32-gcc-libs --noconfirm; \
	/aarch64_gcc.sh; \
	/arm_gcc.sh; \
	/i686_binutils.sh; \
    fi; \
    rm /arm_gcc.sh /aarch64_gcc.sh /i686_binutils.sh
# Creating /VERSION
RUN echo "v$(date +%y%m%d)" > /root/BUILD_DATE
# Setting locale
RUN sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen; \
    locale-gen

USER root
WORKDIR /root
CMD ["/bin/bash"]

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
# Creating dirs for glibc-packages
RUN mkdir -p /data/data/com.termux/files/usr/glibc; \
    ln -s /lib /data/data/com.termux/files/usr/glibc/lib; \
    ln -s /usr/share /data/data/com.termux/files/usr/glibc/share
# Creating hostname
RUN echo "archlinux-builder-v$(date +%y%m%d)" > /etc/hostname

USER root
WORKDIR /root
CMD ["/bin/bash"]

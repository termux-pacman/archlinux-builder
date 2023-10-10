#!/usr/bin/bash

# Setting values
arch="$1"
REPOS=(core extra)
NEED=(base)
DONE=""

case $arch in
	"aarch64"|"armv7h")
		url="https://archlinuxarm.org/${arch}"
		NEED+=(archlinuxarm-keyring);;
	"x86_64") url="https://archive.archlinux.org/repos/last";;
	"i686") url="https://archive.archlinux32.org/repos/last/i686";;
	*)
		echo "Error: no architecture defined (only aarch64, armv7h, x86_64 and i686 are supported)"
		exit 1;;
esac

# Setting functions
set_name() {
	echo $(echo "$1" | sed 's/</ /; s/>/ /; s/=/ /g' | awk '{printf $1}')
}

get_url() {
	if [ "$arch" = "x86_64" ]; then
		echo "${url}/${1}/os/x86_64"
	else
		echo "${url}/${1}"
	fi
}

get_value() {
	local dir="$1"
	local index="$2"
	local i=1
	local res=""
	while true; do
		value_i=$(grep -A $i "%$index%" $dir 2> /dev/null | tail -1)
		if [ -n "$value_i" ]; then
			res+=" $value_i"
			i=$((i+1))
		else
			break
		fi
	done
	echo $res
}

search_pkg() {
	local pkgname="$1"
	# By name
	for i in $(ls db/*/$pkgname-*/desc 2> /dev/null); do
		if [ $(get_value $i NAME) = "$pkgname" ]; then
			echo $i
			return
		fi
	done
	# By provide
	for i in $(grep -s -r '^'$pkgname db/*/ | awk -F ':' '{printf $1 " "}'); do
		for j in $(get_value $i PROVIDES); do
			if [ $(set_name "$j") = $(set_name "$pkgname") ]; then
				echo "$(dirname $i)/desc"
				return
			fi
		done
	done
}

download_pkg() {
        local pkgname=$(set_name $1)
	echo "==> Downloading $pkgname..."
	local dir_desc=$(search_pkg $pkgname)
	if [ -z "$dir_desc" ]; then
		echo "-> Skip by dirdesc"
		return
	fi
	local pkgname=$(get_value ${dir_desc} NAME)
	if $(echo "$DONE" | grep -q " $pkgname "); then
		echo "-> Skip by DONE"
		return
	fi
	local filename=$(get_value ${dir_desc} FILENAME)
	if [ ! -d pkgs ]; then
		mkdir pkgs
	fi
	local repo=$(echo "$dir_desc" | cut -d / -f 2)
	if [ ! -f pkgs/$filename ]; then
		curl -L "$(get_url $repo)/$filename" --output pkgs/$filename
	fi
	echo "-> Extracting $filename"
	local dir_pm_local="archlinux-$arch/var/lib/pacman/local/$(echo $dir_desc | cut -d / -f 3)"
	mkdir -p "$dir_pm_local"
	cp -r "${dir_desc}" "$dir_pm_local/desc"
	mkdir pkg
	if [ "$arch" = "x86_64" ] || [ "$arch" = "i686" ]; then
		tar --use-compress-program=unzstd -xf pkgs/$filename -C pkg
	else
		tar -xJf pkgs/$filename -C pkg
	fi
	cp -r pkg/.MTREE "$dir_pm_local/mtree"
	if [ -f pkg/.INSTALL ]; then
		cp -r pkg/.INSTALL "$dir_pm_local/install"
	fi
	{
		echo "%FILES%"
		if [ -n "$(ls pkg)" ]; then
			find pkg/* | cut -d / -f 2-
		fi
	} > "$dir_pm_local/files"
	if [ -n "$(ls pkg)" ]; then
		cp -r pkg/* archlinux-$arch
	fi
	rm -fr pkg
	DONE+=" $pkgname "
	if [ "$arch" = "aarch64" ] || [ "$arch" = "armv7h" ]; then
		dir_desc="$(dirname $dir_desc)/depends"
	fi
	for i in $(get_value ${dir_desc} DEPENDS); do
		download_pkg $i
	done
}

#main
for repo in ${REPOS[*]}; do
	mkdir -p db/$repo
	file_db="${repo}.db"
	curl -L "$(get_url $repo)/${file_db}" --output db/$file_db
	tar xf db/$file_db -C db/$repo
done
mkdir archlinux-$arch
mkdir -p "archlinux-$arch/var/lib/pacman/sync"
mkdir -p "archlinux-$arch/var/lib/pacman/local"
echo "9" >> "archlinux-$arch/var/lib/pacman/local/ALPM_DB_VERSION"
for i in ${NEED[*]}; do
	download_pkg $i
done
# Setting pacman
if [ "$arch" != "aarch64" ] && [ "$arch" != "armv7h" ]; then
	mv "archlinux-$arch/etc/pacman.d/mirrorlist" "archlinux-$arch/etc/pacman.d/mirrorlist.org"
	if [ "$arch" = "x86_64" ]; then
		curl "https://archlinux.org/mirrorlist/?country=US&protocol=http&protocol=https&ip_version=4&ip_version=6" --output "archlinux-$arch/etc/pacman.d/mirrorlist"
	elif [ "$arch" = "i686" ]; then
		curl "https://archlinux32.org/mirrorlist?country=us&protocol=http&protocol=https&ip_version=4&ip_version=6" --output "archlinux-$arch/etc/pacman.d/mirrorlist"
	fi
	sed -i 's/#Server/Server/g' "archlinux-$arch/etc/pacman.d/mirrorlist"
else
	for i in $(grep -s -r us.mirror.archlinuxarm.org "archlinux-$arch/etc/pacman.d/mirrorlist" | sed 's/ //g'); do
		ser=$(echo "$i" | sed 's/#//; s/=/ = /')
		sed -i "s|# $ser|$ser|" "archlinux-$arch/etc/pacman.d/mirrorlist"
	done
fi
sed -i "s/Architecture = auto/Architecture = $arch/" "archlinux-$arch/etc/pacman.conf"
sed -i 's/#ParallelDownloads/ParallelDownloads/' "archlinux-$arch/etc/pacman.conf"
# Creating archive bootstrap
cd archlinux-$arch
tar cf archlinux-$arch.tar.gz ./*
mv archlinux-$arch.tar.gz ..
cd ..
rm -fr db pkgs archlinux-$arch

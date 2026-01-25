#!/usr/bin/bash

set -e

# Setting values
arch="$1"
REPOS=(core extra)
NEED=(base)

case $arch in
	"aarch64"|"armv7h")
		url="https://archlinuxarm.org/${arch}"
		NEED+=(archlinuxarm-keyring);;
	"x86_64") url="https://archive.archlinux.org";;
	"i686") url="https://archive.archlinux32.org/repos/last/i686";;
	*)
		echo "Error: no architecture defined (only aarch64, armv7h, x86_64 and i686 are supported)"
		exit 1;;
esac

# Setting functions
set_name() {
	echo $(sed 's/</ /; s/>/ /; s/=/ /g' <<< "$1" | awk '{printf $1}')
}

print_desc() {
	echo -e "%${1}%\n${2}\n"
}

get_url() {
	local type="${1}"
	local repo="${2}"
	local pkgname="${3}"
	if [ "$arch" = "x86_64" ]; then
		case "${type}" in
			"repo") echo "${url}/repos/last/${repo}/os/x86_64";;
			"pkg") echo "${url}/packages/${pkgname::1}/${pkgname}"
		esac
	else
		echo "${url}/${repo}"
	fi
}

get_value() {
	local dir="$1"
	local index="$2"
	local i=1
	local res=""
	while true; do
		value_i=$(grep -h -A $i "%$index%" $dir/* 2> /dev/null | tail -1)
		if [ -n "$value_i" ]; then
			res+="\\n$value_i"
			i=$((i+1))
		else
			break
		fi
	done
	echo "${res:2}"
}

search_pkg() {
	local pkgname="$1"
	# By name
	for i in $(ls db/*/$pkgname-*/desc 2> /dev/null); do
		if [ $(get_value ${i%/*} NAME) = "$pkgname" ]; then
			echo ${i%/*}
			return
		fi
	done
	# By provide
	for i in $(grep -s -r "^$pkgname" db/*/ | awk -F ':' '{printf $1 " "}'); do
		for j in $(get_value ${i%/*} PROVIDES); do
			if [ $(set_name "$j") = $(set_name "$pkgname") ]; then
				dirname $i
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
		echo "-> Skip, was not found"
		return
	fi
	local filename=$(get_value ${dir_desc} FILENAME)
	if [ ! -d pkgs ]; then
		mkdir pkgs
	elif [ -f pkgs/$filename ]; then
		echo "-> Skip, already installed"
		return
	fi
	local repo=$(cut -d / -f 2 <<< "$dir_desc")
	if [ ! -f pkgs/$filename ]; then
		curl -L "$(get_url pkg $repo $pkgname)/$filename" --output pkgs/$filename
	fi
	echo "-> Extracting $filename"
	local dir_pm_local="archlinux-$arch/var/lib/pacman/local/$(cut -d / -f 3 <<< $dir_desc)"
	mkdir -p "$dir_pm_local"
	{
		print_desc "NAME" "$pkgname"
		print_desc "INSTALLDATE" "$(date +%s)"
		print_desc "VALIDATION" "pgp"
		for key in VERSION BASE DESC URL ARCH BUILDDATE PACKAGER ISIZE GROUPS LICENSE REPLACES DEPENDS OPTDEPENDS CONFLICTS PROVIDES; do
			local key_value=$(get_value ${dir_desc} $key)
			if [[ -n "$key_value" ]]; then
				print_desc "$(test ${key} = 'ISIZE' && echo 'SIZE' || echo ${key})" "$key_value"
			fi
		done
	} > "$dir_pm_local/desc"
	{
		echo "%FILES%"
		fakeroot -- tar $([[ "$arch" = "x86_64" || "$arch" = "i686" ]] && echo '--use-compress-program=unzstd') \
			-xvf pkgs/$filename -C archlinux-$arch --exclude='.BUILDINFO' --exclude='.PKGINFO' | \
			grep -Ev '^.(BUILDINFO|MTREE|PKGINFO|INSTALL)' || true
	} > "$dir_pm_local/files"
	mv archlinux-$arch/.MTREE "$dir_pm_local/mtree"
	if [ -f archlinux-$arch/.INSTALL ]; then
		mv archlinux-$arch/.INSTALL "$dir_pm_local/install"
	fi
	for i in $(get_value ${dir_desc} DEPENDS | sed 's|\\n| |g'); do
		download_pkg $i
	done
}

#main
for repo in ${REPOS[*]}; do
	mkdir -p db/$repo
	file_db="${repo}.db"
	curl -L "$(get_url repo $repo)/${file_db}" --output db/$file_db
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
sed -i 's|^#*.Server|Server|g' "archlinux-$arch/etc/pacman.d/mirrorlist"
sed -i "s/^Architecture = auto/Architecture = $arch/; \
	s/^#ParallelDownloads/ParallelDownloads/;
	s/^DownloadUser/#DownloadUser/" "archlinux-$arch/etc/pacman.conf"

# Creating archive bootstrap
cd archlinux-$arch
fakeroot -- tar -cf archlinux-$arch.tar.gz ./*
mv archlinux-$arch.tar.gz ..
cd ..
rm -fr db pkgs archlinux-$arch

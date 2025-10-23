#!/bin/bash

pkgname=$1

useradd builder -m
echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod -R a+rw .

cat << EOM >> /etc/pacman.conf
[archlinuxcn]
Server = https://repo.archlinuxcn.org/x86_64
EOM

pacman-key --init
pacman-key --lsign-key "farseerfc@archlinux.org"
pacman -Sy --noconfirm archlinux{,cn}-keyring
pacman -Syu --noconfirm yay
if [ ! -z "$INPUT_PREINSTALLPKGS" ]; then
    pacman -Su --noconfirm "$INPUT_PREINSTALLPKGS"
fi

sudo --set-home -u builder yay -S --noconfirm --builddir=./ "$pkgname"

# Find the actual build directory (pkgbase) created by yay.
# Some AUR packages use a different pkgbase directory name,
# e.g. otf-space-grotesk has a pkgbase 38c3-styles, 
# when using yay -S otf-space-grotesk, it's built under folder 38c3-styles.
function get_pkgbase(){
  pacman -S --needed --noconfirm jq
  local pkg="$1"   # e.g. otf-space-grotesk
  url="https://aur.archlinux.org/rpc/?v=5&type=info&arg=${pkg}"
  resp="$(curl -sS "$url")"
  pkgbase="$(printf '%s' "$resp" | jq -r '.results[0].PackageBase // .results[0].Name')"
  if [ -z "$pkgbase" ] || [ "$pkgbase" = "null" ]; then
    echo "Package not found in AUR: $pkg" >&2
    exit 1
  fi
  echo "$pkgbase"
}

if [[ -d "$pkgname" ]];
  then pkgdir=$pkgname
  else pkgdir=$(get_pkgbase $pkgname)
fi
python3 ../build-aur-action/encode_name.py

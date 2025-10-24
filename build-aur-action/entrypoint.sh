#!/bin/bash

set -euo pipefail

pkgname=$1

useradd builder -m
echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod -R a+rw .

PACMAN_FLAGS="--needed --noconfirm"

install-yay(){
  sudo --set-home -u builder git clone https://aur.archlinux.org/yay-bin.git buildyay
  cd buildyay
  sudo --set-home -u builder makepkg -si --noconfirm
  cd ..
  rm -rf buildyay
}
install-yay
if [ ! -z "$INPUT_PREINSTALLPKGS" ]; then
    pacman -S ${PACMAN_FLAGS} "$INPUT_PREINSTALLPKGS"
fi

sudo --set-home -u builder yay -S ${PACMAN_FLAGS} --builddir=./ "$pkgname"

# Find the actual build directory (pkgbase) created by yay.
# Some AUR packages use a different pkgbase directory name,
# e.g. otf-space-grotesk has a pkgbase 38c3-styles, 
# when using yay -S otf-space-grotesk, it's built under folder 38c3-styles.
function get_pkgbase(){
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
  then pkgdir="$pkgname"
  else
    pkgdir="$(get_pkgbase $pkgname)"
fi

echo "The pkgdir is $pkgdir"
echo "The pkgname is $pkgname"
cd "$pkgdir"
python3 ../build-aur-action/encode_name.py

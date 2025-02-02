#!/bin/bash
set -euo pipefail

unpack_rpms() {
  mkdir -p ./firmware/build/boot/efi
  dnf download --releasever=41 --destdir=./firmware/rpm uboot-images-armv8 bcm283x-firmware bcm2711-firmware bcm2835-firmware bcm283x-overlays
  for rpm in ./firmware/rpm/*.rpm; do
    rpm2cpio "${rpm}" | cpio -idv -D ./firmware/build
  done
  cp ./firmware/build/usr/share/uboot/rpi_arm64/u-boot.bin ./firmware/build/boot/efi/rpi-u-boot.bin
}

install_firmware() {
  if [ ! -d ./firmware/build ]; then
    echo "The ./firmware/build directory does not exist. Make sure to run unpack_rpms before invoking this function."
    exit 1
  fi
  if [ -z "${TARGET_DEV}" ]; then
    echo "The TARGET_DEV environment variable is not set."
    exit 2
  fi
  mkdir -p ./firmware/efi
  efipart=$(lsblk "${TARGET_DEV}" -J -oLABEL,PATH | jq -r '.blockdevices[] | select(.label == "EFI-SYSTEM").path')
  sudo mount "${efipart}" ./firmware/efi
  sudo rsync -rldvh --ignore-existing ./firmware/build/boot/efi/ ./firmware/efi/
  sudo umount "${efipart}"
  rm -rf ./firmware/efi
}

$1
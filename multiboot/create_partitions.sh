#!/bin/bash

# Partition and create file systems on the new disk

# Use MiB boundaries to get the correct partition alignment.
# Escape spaces in names to protect them from the shell.

help()
{
	echo "Usage: $0 <dev>"
	exit 1
}

if [ $# -ne 1 ]; then
  help
fi
TARGET_DEV="$1"

# End of configurable parameters
umount -q ${TARGET_DEV}{1,2,3,5,6,7,8}
echo "Running parted ..."
parted ${TARGET_DEV} --script mklabel gpt
partprobe -s ${TARGET_DEV}

parted ${TARGET_DEV} --script -a optimal -- mkpart primary fat32 1MiB 257MiB \
name 1 \"EFI\ System\" set 1 esp on set 1 boot on
partprobe -s ${TARGET_DEV}

# REDOS 7.2
parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 257MiB 13757MiB \
name 2 "redos"
partprobe -s ${TARGET_DEV}

# Debian Edelweiss
parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 13757MiB 30757MiB \
name 3 "edelsw"
partprobe -s ${TARGET_DEV}

# Linux swap
parted ${TARGET_DEV} --script -a optimal -- mkpart primary linux-swap 30757MiB 34757MiB \
name 4 "swap"
partprobe -s ${TARGET_DEV}

# Alt Linux
parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 34757MiB 48757MiB \
name 5 "alt"
partprobe -s ${TARGET_DEV}

# Astra Linux 4.11.4
parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 48757MiB 70357MiB \
name 6 "astra"
partprobe -s ${TARGET_DEV}

# Debian Wayland
parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 70357MiB 95435MiB \
name 7 "wayland"
partprobe -s ${TARGET_DEV}

# Ubuntu 20. Reserve space for superblock at the end
parted ${TARGET_DEV} --script -a optimal -- mkpart primary ext4 95435MiB -2048s \
name 8 "ubuntu"
/usr/sbin/partprobe -s ${TARGET_DEV}

echo "Creating file systems ..."
sync
yes | mkfs.vfat -F 32 ${TARGET_DEV}1
sync
yes | mkfs.ext4 ${TARGET_DEV}2
sync
yes | mkfs.ext4 ${TARGET_DEV}3
sync
mkswap ${TARGET_DEV}4
yes | mkfs.ext4 ${TARGET_DEV}5
sync
yes | mkfs.ext4 ${TARGET_DEV}6
sync
yes | mkfs.ext4 ${TARGET_DEV}7
sync
yes | mkfs.ext4 ${TARGET_DEV}8
sync

mkdir -p /tmp/{efi,redos,edelw,alt,astra,wayland,ubuntu}
# skip dev 4 as it is a swap partition
mount ${TARGET_DEV}1 /tmp/efi
mount ${TARGET_DEV}2 /tmp/redos
mount ${TARGET_DEV}3 /tmp/edelw
mount ${TARGET_DEV}5 /tmp/alt
mount ${TARGET_DEV}6 /tmp/astra
mount ${TARGET_DEV}7 /tmp/wayland
mount ${TARGET_DEV}8 /tmp/ubuntu
df -h | grep ${TARGET_DEV}
echo
echo "Done."
